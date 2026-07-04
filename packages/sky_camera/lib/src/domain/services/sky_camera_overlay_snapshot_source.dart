import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';

abstract class SkyCameraOverlaySnapshotSource {
  Future<void> start();
  Stream<SkyCameraOverlaySnapshot> watch();
  Future<void> dispose();
}
