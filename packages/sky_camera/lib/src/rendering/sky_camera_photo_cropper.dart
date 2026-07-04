import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/models/sky_camera_media_format.dart';

class SkyCameraPhotoCropper {
  const SkyCameraPhotoCropper();

  Future<SkyCameraCapturedPhoto> cropToMediaFormat(
    SkyCameraCapturedPhoto photo,
  ) async {
    final codec = await ui.instantiateImageCodec(photo.bytes);
    final frame = await codec.getNextFrame();
    final sourceImage = frame.image;
    final sourceSize = Size(
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );
    final sourceRect = _centerCropRect(
      sourceSize,
      SkyCameraMediaFormat.portraitAspectRatio,
    );
    final outputWidth = sourceRect.width.round();
    final outputHeight = sourceRect.height.round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
      sourceImage,
      sourceRect,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    final outputImage = await picture.toImage(outputWidth, outputHeight);
    final byteData = await outputImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    sourceImage.dispose();
    outputImage.dispose();
    picture.dispose();
    codec.dispose();
    if (byteData == null) {
      throw StateError('Could not encode the cropped camera photo.');
    }
    return SkyCameraCapturedPhoto(
      bytes: byteData.buffer.asUint8List(),
      fileExtension: 'png',
      capturedAt: photo.capturedAt,
    );
  }

  Rect _centerCropRect(Size sourceSize, double targetAspectRatio) {
    final sourceAspectRatio = sourceSize.width / sourceSize.height;
    if (sourceAspectRatio > targetAspectRatio) {
      final width = sourceSize.height * targetAspectRatio;
      return Rect.fromLTWH(
        (sourceSize.width - width) / 2,
        0,
        width,
        sourceSize.height,
      );
    }
    final height = sourceSize.width / targetAspectRatio;
    return Rect.fromLTWH(
      0,
      (sourceSize.height - height) / 2,
      sourceSize.width,
      height,
    );
  }
}
