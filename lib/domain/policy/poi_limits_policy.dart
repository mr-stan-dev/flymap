class PoiLimitsPolicy {
  static const int freeMaxPois = 20;
  static const int proMaxPois = 200;

  const PoiLimitsPolicy._();

  static int maxPoisForTier({required bool isProUser}) {
    return isProUser ? proMaxPois : freeMaxPois;
  }
}
