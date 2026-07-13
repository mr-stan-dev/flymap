import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';

abstract class SkyCameraExportService {
  Future<SkyCameraSavedCapture> saveCapture({
    required SkyCameraCapturedPhoto originalPhoto,
    required SkyCameraOverlaySnapshot snapshot,
    required List<int> overlayBytes,
  });

  /// Persists a clean video recording plus its 1 Hz overlay track. The
  /// overlay is NOT burned here — that happens lazily when the user shares
  /// or saves the video.
  Future<SkyCameraSavedCapture> saveVideoCapture({
    required SkyCameraCapturedVideo video,
    required SkyCameraOverlaySnapshot snapshot,
    required List<SkyCameraVideoTrackSample> track,
  });
}
