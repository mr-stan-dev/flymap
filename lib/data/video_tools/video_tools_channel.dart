import 'package:flutter/services.dart';

/// Basic properties of a video file as the native side reads them.
class VideoToolsInfo {
  const VideoToolsInfo({
    required this.width,
    required this.height,
    required this.durationMs,
  });

  /// Display dimensions (rotation already applied).
  final int width;
  final int height;
  final int durationMs;
}

/// Dart side of the native video toolbox (AVFoundation on iOS, Media3 /
/// MediaMetadataRetriever on Android): poster extraction and share-time
/// overlay burn-in for sky-camera videos.
class VideoToolsChannel {
  const VideoToolsChannel();

  static const _channel = MethodChannel('app.flymap/video_tools');
  static const _methodExtractPoster = 'extractPoster';
  static const _methodGetVideoInfo = 'getVideoInfo';
  static const _methodBurnOverlay = 'burnOverlay';

  /// Receives 0..1 transcode progress pushed by the native side while a
  /// burn runs. Burns are UI-gated to one at a time, so a single static
  /// listener suffices.
  static void Function(double fraction)? _burnProgressListener;
  static bool _callHandlerInstalled = false;

  static void _ensureCallHandler() {
    if (_callHandlerInstalled) return;
    _callHandlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'burnProgress') {
        final fraction = (call.arguments as num?)?.toDouble();
        if (fraction != null) {
          _burnProgressListener?.call(fraction.clamp(0.0, 1.0));
        }
      }
      return null;
    });
  }

  /// Returns PNG bytes of the frame at [atMs] into the video.
  Future<Uint8List> extractPoster({
    required String videoPath,
    int atMs = 0,
  }) async {
    final bytes = await _channel.invokeMethod<Uint8List>(
      _methodExtractPoster,
      {'videoPath': videoPath, 'atMs': atMs},
    );
    if (bytes == null || bytes.isEmpty) {
      throw PlatformException(
        code: 'empty_poster',
        message: 'Poster extraction returned no image data.',
      );
    }
    return bytes;
  }

  Future<VideoToolsInfo> getVideoInfo({required String videoPath}) async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      _methodGetVideoInfo,
      {'videoPath': videoPath},
    );
    final width = (result?['width'] as num?)?.toInt();
    final height = (result?['height'] as num?)?.toInt();
    final durationMs = (result?['durationMs'] as num?)?.toInt();
    if (width == null || height == null || durationMs == null) {
      throw PlatformException(
        code: 'invalid_video_info',
        message: 'getVideoInfo returned incomplete data.',
      );
    }
    return VideoToolsInfo(
      width: width,
      height: height,
      durationMs: durationMs,
    );
  }

  /// Transcodes [videoPath] into [outputPath] with the overlay frames
  /// composited on top. [overlayFramePaths] hold one PNG per
  /// [frameDurationMs] of video, in order, each sized to the video's display
  /// dimensions; the last frame covers any remainder.
  Future<void> burnOverlay({
    required String videoPath,
    required List<String> overlayFramePaths,
    required int frameDurationMs,
    required String outputPath,
    void Function(double fraction)? onProgress,
  }) async {
    _ensureCallHandler();
    _burnProgressListener = onProgress;
    try {
      await _channel.invokeMethod<void>(_methodBurnOverlay, {
        'videoPath': videoPath,
        'overlayFramePaths': overlayFramePaths,
        'frameDurationMs': frameDurationMs,
        'outputPath': outputPath,
      });
    } finally {
      _burnProgressListener = null;
    }
  }
}
