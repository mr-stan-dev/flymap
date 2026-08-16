/// Compile-time feature toggles.
class FeatureFlags {
  const FeatureFlags._();

  /// Experimental Sky Camera video recording. Disabled for release builds
  /// until the share-ready recording architecture is revisited and passes the
  /// device validation described in `docs/sky_camera_video_architecture.md`.
  ///
  /// Development opt-in: `--dart-define=FLYMAP_SKY_CAMERA_VIDEO=true`.
  static const bool skyCameraVideoCapture = bool.fromEnvironment(
    'FLYMAP_SKY_CAMERA_VIDEO',
    defaultValue: false,
  );
}
