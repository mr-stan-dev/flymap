import 'dart:ui';

import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sky_camera/sky_camera.dart';

typedef SkyCameraShareFiles =
    Future<ShareResult> Function({
      required List<XFile> files,
      required Rect sharePositionOrigin,
    });

class FlymapSkyCameraShareService implements SkyCameraShareService {
  FlymapSkyCameraShareService({
    required AppAnalytics analytics,
    SkyCameraShareFiles shareFiles = _shareFiles,
  }) : _analytics = analytics,
       _shareFilesCallback = shareFiles;

  final AppAnalytics _analytics;
  final SkyCameraShareFiles _shareFilesCallback;

  @override
  Future<void> shareCapture({
    required SkyCameraSavedCapture capture,
    required Rect sharePositionOrigin,
  }) async {
    await _analytics.log(const SkyPhotoShareEvent());
    await _shareFilesCallback(
      files: [XFile(capture.overlayPath)],
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<void> shareMediaItems({
    required List<SkyCameraMediaItem> captures,
    required Rect sharePositionOrigin,
    required String source,
  }) async {
    final unresolvedVideo = captures.where((capture) {
      if (!capture.isVideo) return false;
      final rendition = capture.selectedRendition;
      return rendition?.mediaType != SkyCameraMediaType.video ||
          (rendition?.path.trim().isEmpty ?? true);
    });
    if (unresolvedVideo.isNotEmpty) {
      throw StateError(
        'Sky-camera videos must have an overlay rendition before sharing.',
      );
    }
    final files = [
      for (final capture in captures)
        if (capture.sharePath.trim().isNotEmpty) XFile(capture.sharePath),
    ];
    if (files.isEmpty) return;
    final videoCount = captures.where((capture) => capture.isVideo).length;
    if (videoCount == 0) {
      await _analytics.log(const SkyPhotoShareEvent());
      await _shareFilesCallback(
        files: files,
        sharePositionOrigin: sharePositionOrigin,
      );
      return;
    }

    final photoCount = captures.length - videoCount;
    try {
      final result = await _shareFilesCallback(
        files: files,
        sharePositionOrigin: sharePositionOrigin,
      );
      await _analytics.log(
        SkyVideoShareEvent(
          source: source,
          result: result.status.name,
          videoCount: videoCount,
          photoCount: photoCount,
        ),
      );
    } catch (_) {
      await _analytics.log(
        SkyVideoShareEvent(
          source: source,
          result: 'failed',
          videoCount: videoCount,
          photoCount: photoCount,
        ),
      );
      rethrow;
    }
  }

  static Future<ShareResult> _shareFiles({
    required List<XFile> files,
    required Rect sharePositionOrigin,
  }) => Share.shareXFiles(files, sharePositionOrigin: sharePositionOrigin);
}
