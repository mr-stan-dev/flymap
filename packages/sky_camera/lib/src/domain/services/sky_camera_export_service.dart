import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';

abstract class SkyCameraExportService {
  Future<SkyCameraSavedCapture> saveCapture({
    required SkyCameraCapturedPhoto originalPhoto,
    required SkyCameraOverlaySnapshot snapshot,
    required List<int> overlayBytes,
  });
}
