class SkyCameraMediaFormat {
  const SkyCameraMediaFormat._();

  static const portraitAspectRatio = 9 / 16;

  /// Hard cap per clip: long enough for a full takeoff roll or landing
  /// approach, short enough that the share-time overlay burn-in stays a
  /// one-progress-bar wait and per-clip storage stays reasonable.
  static const maxVideoDuration = Duration(minutes: 10);
}
