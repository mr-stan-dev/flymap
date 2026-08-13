import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flymap/data/video_tools/video_tools_channel.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_overlay_timeline.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sky_camera/sky_camera.dart';

/// Thrown when the user cancels an overlay burn; callers dismiss quietly
/// instead of surfacing an error.
class SkyCameraRenditionCancelled implements Exception {
  const SkyCameraRenditionCancelled();
}

class SkyCameraRenditionInsufficientStorage implements Exception {
  const SkyCameraRenditionInsufficientStorage();
}

/// Cooperative cancellation for [SkyCameraVideoRenditionService]: the frame
/// rasterization loop polls it, and the native transcode is cancelled
/// through the video tools channel.
class SkyCameraRenditionCancellation {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Creates (and caches) the overlay-burned rendition of a sky-camera video.
///
/// Recording saves the clean clip plus its 1 Hz GPS track; the burned MP4 is
/// produced here the first time the user shares or saves — one overlay PNG
/// per second rasterized in Dart (pixel-identical to the photo overlay),
/// composited by the native hardware transcoder.
class SkyCameraVideoRenditionService {
  SkyCameraVideoRenditionService({
    required SkyCameraMediaRepository repository,
    VideoToolsChannel videoTools = const VideoToolsChannel(),
    SkyCameraOverlayComposer composer = const SkyCameraOverlayComposer(),
    Future<int?> Function()? availableStorageBytes,
    this.minimumFreeBytesAfterExport = defaultMinimumFreeBytesAfterExport,
  }) : _repository = repository,
       _videoTools = videoTools,
       _composer = composer,
       _availableStorageBytes = availableStorageBytes,
       assert(minimumFreeBytesAfterExport >= 0);

  static const String renditionId = 'default';
  static const String _skinId = 'flymap_default_v1';
  static const int _frameDurationMs = 1000;
  static const int _storageCheckFrameInterval = 10;
  static const int defaultMinimumFreeBytesAfterExport = 512 * 1024 * 1024;

  final SkyCameraMediaRepository _repository;
  final VideoToolsChannel _videoTools;
  final SkyCameraOverlayComposer _composer;
  final Future<int?> Function()? _availableStorageBytes;
  final int minimumFreeBytesAfterExport;
  final Logger _logger = const Logger('SkyCameraVideoRendition');

  /// Returns the item whose [SkyCameraMediaItem.sharePath] is the burned
  /// video, producing and persisting the rendition on first use.
  ///
  /// [onProgress] reports the overall 0..1 progress: overlay-frame
  /// rasterization is weighted as the first ~35%, the native transcode as
  /// the remainder — roughly matching their wall-clock split.
  Future<SkyCameraMediaItem> ensureOverlayRendition(
    SkyCameraMediaItem item, {
    required SkyCameraStrings strings,
    void Function(double fraction)? onProgress,
    SkyCameraRenditionCancellation? cancellation,
  }) async {
    if (item.mediaType != SkyCameraMediaType.video) return item;
    final selectedRendition = item.selectedRendition;
    if (selectedRendition != null &&
        selectedRendition.mediaType == SkyCameraMediaType.video &&
        selectedRendition.path.trim().isNotEmpty) {
      return item;
    }
    const rasterWeight = 0.35;

    final sourceFile = File(item.sourcePath);
    await _ensureStorageForRendition(sourceFile);
    final info = await _videoTools.getVideoInfo(videoPath: item.sourcePath);
    final frameCount = (info.durationMs / _frameDurationMs).ceil().clamp(
      1,
      SkyCameraMediaFormat.maxVideoDuration.inSeconds,
    );
    final timeline = SkyCameraVideoOverlayTimeline(item);

    final tempBase = await getTemporaryDirectory();
    final framesDirectory = Directory(
      p.join(tempBase.path, 'sky_camera_overlay_frames', item.id),
    );
    await framesDirectory.create(recursive: true);

    try {
      final framePaths = <String>[];
      for (var index = 0; index < frameCount; index++) {
        if (cancellation?.isCancelled ?? false) {
          throw const SkyCameraRenditionCancelled();
        }
        if (index % _storageCheckFrameInterval == 0) {
          await _ensureStorageForRendition(sourceFile);
        }
        final bytes = await _composer.composeOverlayFrame(
          width: info.width,
          height: info.height,
          snapshot: timeline.snapshotAt(index * _frameDurationMs),
          strings: strings,
          metricsPosition: SkyCameraMetricsPosition.initial,
        );
        final framePath = p.join(framesDirectory.path, 'frame_$index.png');
        await File(framePath).writeAsBytes(bytes, flush: true);
        framePaths.add(framePath);
        onProgress?.call(rasterWeight * (index + 1) / frameCount);
      }

      final renditionPath = p.join(
        p.dirname(item.sourcePath),
        '${item.id}_overlay.mp4',
      );
      if (cancellation?.isCancelled ?? false) {
        throw const SkyCameraRenditionCancelled();
      }
      await _ensureStorageForRendition(sourceFile);
      try {
        await _videoTools.burnOverlay(
          videoPath: item.sourcePath,
          overlayFramePaths: framePaths,
          frameDurationMs: _frameDurationMs,
          outputPath: renditionPath,
          onProgress: (fraction) =>
              onProgress?.call(rasterWeight + (1 - rasterWeight) * fraction),
        );
      } on PlatformException catch (error) {
        // The native sides delete their partial output; this keeps legacy
        // behavior safe if that ever fails.
        try {
          await File(renditionPath).delete();
        } catch (_) {}
        if (error.code == VideoToolsChannel.burnCancelledCode) {
          throw const SkyCameraRenditionCancelled();
        }
        rethrow;
      }
      onProgress?.call(1);

      final updated = item.copyWith(
        renditions: [
          SkyCameraMediaRendition(
            id: renditionId,
            skinId: _skinId,
            mediaType: SkyCameraMediaType.video,
            path: renditionPath,
            previewImagePath: item.previewImagePath,
            createdAt: DateTime.now(),
          ),
        ],
        selectedRenditionId: renditionId,
      );
      // addCapture is an upsert on the item id.
      await _repository.addCapture(updated);
      return updated;
    } on SkyCameraRenditionCancelled {
      rethrow;
    } catch (error) {
      _logger.error('Overlay rendition failed for ${item.id}: $error');
      rethrow;
    } finally {
      try {
        await framesDirectory.delete(recursive: true);
      } catch (_) {
        // Temp cleanup is best-effort.
      }
    }
  }

  /// Cancels the in-flight native transcode, if any. Pair with
  /// [SkyCameraRenditionCancellation.cancel] to stop the raster loop too.
  Future<void> cancelActiveBurn() => _videoTools.cancelBurn();

  Future<void> _ensureStorageForRendition(File sourceFile) async {
    final int? availableStorageBytes;
    try {
      availableStorageBytes =
          await (_availableStorageBytes?.call() ??
              _videoTools.getAvailableStorageBytes());
    } catch (error) {
      // Match recording resource checks: failure to query the OS must not make
      // an otherwise valid video permanently unshareable.
      _logger.error('Could not read storage before video rendition: $error');
      return;
    }
    if (availableStorageBytes == null) return;
    final sourceBytes = await sourceFile.length();
    // The burned rendition is a second video alongside the clean original.
    // Keep a fixed reserve for temporary overlay PNGs and normal app writes;
    // repeated checks account for those frames as they accumulate.
    final requiredBytes = sourceBytes + minimumFreeBytesAfterExport;
    if (availableStorageBytes < requiredBytes) {
      throw const SkyCameraRenditionInsufficientStorage();
    }
  }
}
