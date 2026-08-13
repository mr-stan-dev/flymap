/// Compile-time feature toggles.
class FeatureFlags {
  const FeatureFlags._();

  /// Sky camera video recording (capture-mode switch, recording, share-time
  /// overlay burn-in). Enabled by default; builds can disable it with
  /// `--dart-define=FLYMAP_SKY_CAMERA_VIDEO=false` if an emergency rollback is
  /// needed.
  ///
  /// Build override: `--dart-define=FLYMAP_SKY_CAMERA_VIDEO=false`.
  static const bool skyCameraVideoCapture = bool.fromEnvironment(
    'FLYMAP_SKY_CAMERA_VIDEO',
    defaultValue: true,
  );
}
