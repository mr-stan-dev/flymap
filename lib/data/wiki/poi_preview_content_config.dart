enum PoiPreviewContentMode { summary, fullText }

class PoiPreviewContentConfig {
  PoiPreviewContentConfig._();

  /// Current mode for POI preview/download text content.
  ///
  /// Switch to [PoiPreviewContentMode.summary] if we need smaller payloads.
  static const PoiPreviewContentMode mode = PoiPreviewContentMode.fullText;

  static const int weakSummaryMinChars = 120;

  // Summary mode soft-limit policy.
  static const int summaryTargetChars = 1200;
  static const int summaryMaxChars = 1800;

  // Full-text mode policy.
  // Keep null to store full text without truncation.
  static const int? fullTextTargetChars = null;
  static const int? fullTextMaxChars = null;
}
