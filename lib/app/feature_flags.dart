/// Compile-time feature toggles.
class FeatureFlags {
  const FeatureFlags._();

  /// Sky camera video recording (capture-mode switch, recording, share-time
  /// overlay burn-in). Shipping dark in the current release; flip the
  /// default to `true` for the next release.
  ///
  /// Local/dev override: `--dart-define=FLYMAP_SKY_CAMERA_VIDEO=true`.
  static const bool skyCameraVideoCapture = bool.fromEnvironment(
    'FLYMAP_SKY_CAMERA_VIDEO',
    defaultValue: false,
  );
}
