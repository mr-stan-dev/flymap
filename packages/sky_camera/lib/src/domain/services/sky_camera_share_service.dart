import 'dart:ui';

import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';

abstract class SkyCameraShareService {
  Future<void> shareCapture({
    required SkyCameraSavedCapture capture,
    required Rect sharePositionOrigin,
  });
}
