import 'dart:typed_data';

import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';

class SkyCameraCapturedPhoto {
  const SkyCameraCapturedPhoto({
    required this.bytes,
    required this.fileExtension,
    required this.capturedAt,
  });

  final Uint8List bytes;
  final String fileExtension;
  final DateTime capturedAt;
}

/// A finished clean video recording on disk (no overlay burned in).
class SkyCameraCapturedVideo {
  const SkyCameraCapturedVideo({
    required this.filePath,
    required this.fileExtension,
    required this.capturedAt,
    required this.duration,
  });

  final String filePath;
  final String fileExtension;

  /// When the recording STARTED — track sample offsets are relative to it.
  final DateTime capturedAt;
  final Duration duration;
}

/// One 1 Hz GPS/overlay sample captured while a video was recording.
class SkyCameraVideoTrackSample {
  const SkyCameraVideoTrackSample({
    required this.offsetMs,
    required this.snapshot,
  });

  /// Milliseconds since the recording started.
  final int offsetMs;
  final SkyCameraOverlaySnapshot snapshot;
}

class SkyCameraSavedCapture {
  const SkyCameraSavedCapture({
    required this.id,
    required this.originalPath,
    required this.overlayPath,
    this.isVideo = false,
  });

  final String id;
  final String originalPath;

  /// Overlay-burned photo for photos; poster frame for videos. Always an
  /// image — it drives the in-session thumbnail.
  final String overlayPath;
  final bool isVideo;
}
