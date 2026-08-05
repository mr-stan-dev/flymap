enum WeatherWindTone { normal, warning, strong }

class WeatherWindPresentation {
  const WeatherWindPresentation({
    required this.label,
    required this.filledBars,
    required this.tone,
  });

  final String label;
  final int filledBars;
  final WeatherWindTone tone;
}

/// Shared airport-card wind bands for the live weather screen and exported
/// image/video cards.
const double breezyThresholdMs = 5;
const double windyThresholdMs = 8;
const double strongWindThresholdMs = 14;

WeatherWindPresentation weatherWindPresentation(
  double speedMs,
  dynamic translations,
) {
  return switch (speedMs) {
    < 2 => WeatherWindPresentation(
      label: translations.windCalm,
      filledBars: 1,
      tone: WeatherWindTone.normal,
    ),
    < breezyThresholdMs => WeatherWindPresentation(
      label: translations.windLight,
      filledBars: 1,
      tone: WeatherWindTone.normal,
    ),
    < windyThresholdMs => WeatherWindPresentation(
      label: translations.windBreezy,
      filledBars: 2,
      tone: WeatherWindTone.normal,
    ),
    < strongWindThresholdMs => WeatherWindPresentation(
      label: translations.windWindy,
      filledBars: 3,
      tone: WeatherWindTone.warning,
    ),
    _ => WeatherWindPresentation(
      label: translations.windStrong,
      filledBars: 3,
      tone: WeatherWindTone.strong,
    ),
  };
}
