import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';

abstract class SkyCameraObserver {
  Future<void> onOpened({required SkyCameraOverlaySnapshot snapshot});

  Future<void> onPhotoCaptured({required SkyCameraOverlaySnapshot snapshot});

  Future<void> onPhotoSaved({
    required SkyCameraOverlaySnapshot snapshot,
    required bool saveCleanCopy,
    required bool saveOverlayCopy,
  });

  Future<void> onShareTapped({required SkyCameraOverlaySnapshot snapshot});
}
