import 'dart:typed_data';

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

class SkyCameraSavedCapture {
  const SkyCameraSavedCapture({
    required this.id,
    required this.originalPath,
    required this.overlayPath,
  });

  final String id;
  final String originalPath;
  final String overlayPath;
}
