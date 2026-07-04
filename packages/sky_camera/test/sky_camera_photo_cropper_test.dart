import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  test('center-crops captured photos to portrait 9:16', () async {
    final sourceBytes = await _createImage(width: 120, height: 160);
    final photo = SkyCameraCapturedPhoto(
      bytes: sourceBytes,
      fileExtension: 'jpg',
      capturedAt: DateTime(2026, 7, 3),
    );

    final cropped = await const SkyCameraPhotoCropper().cropToMediaFormat(
      photo,
    );
    final codec = await ui.instantiateImageCodec(cropped.bytes);
    final frame = await codec.getNextFrame();

    expect(frame.image.width, 90);
    expect(frame.image.height, 160);
    expect(
      frame.image.width / frame.image.height,
      SkyCameraMediaFormat.portraitAspectRatio,
    );
    expect(cropped.fileExtension, 'png');
    expect(cropped.capturedAt, photo.capturedAt);

    frame.image.dispose();
    codec.dispose();
  });
}

Future<Uint8List> _createImage({
  required int width,
  required int height,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFF123456),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}
