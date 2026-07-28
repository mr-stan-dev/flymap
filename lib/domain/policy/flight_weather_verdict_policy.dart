import 'package:flymap/domain/entity/flight_weather.dart';

/// One-line answer to "will you see the ground?".
enum WindowVerdict {
  /// Mostly unobstructed ground views.
  clearViews,

  /// Broken cover — views come and go.
  patchyClouds,

  /// Dense low/mid cover with clear sky above: the famously pretty white
  /// carpet. Framed positively — it IS a view, just not of the ground.
  cloudCarpet,

  /// Dense cover below AND above cruise: grey out the window.
  overcast,
}

/// A contiguous stretch of the route sharing one verdict, for the
/// "clear until the Alps, carpet over Bavaria" expectation line.
class WeatherSegment {
  const WeatherSegment({
    required this.startProgress,
    required this.endProgress,
    required this.verdict,
  });

  final double startProgress;
  final double endProgress;
  final WindowVerdict verdict;

  double get midProgress => (startProgress + endProgress) / 2;
  double get length => endProgress - startProgress;
}

/// Turns route cloud samples into the overall window verdict and
/// per-segment breakdown. Pure math, no I/O.
class FlightWeatherVerdictPolicy {
  const FlightWeatherVerdictPolicy._();

  /// Below this share of hidden ground a stretch counts as clear.
  static const double clearThreshold = 25;

  /// Above this share the ground is effectively gone (carpet/overcast).
  static const double hiddenThreshold = 60;

  /// High-cirrus cover above which a hidden stretch reads as grey overcast
  /// rather than a sunlit cloud carpet.
  static const double overcastHighThreshold = 60;

  static WindowVerdict sampleVerdict(RouteCloudSample sample) {
    final hidden = sample.groundHiddenPercent;
    if (hidden < clearThreshold) return WindowVerdict.clearViews;
    if (hidden < hiddenThreshold) return WindowVerdict.patchyClouds;
    return sample.cloudHighPercent >= overcastHighThreshold
        ? WindowVerdict.overcast
        : WindowVerdict.cloudCarpet;
  }

  /// Overall verdict: mean hidden share across samples (uniform spacing
  /// makes the plain mean distance-weighted already).
  static WindowVerdict overallVerdict(List<RouteCloudSample> samples) {
    if (samples.isEmpty) return WindowVerdict.patchyClouds;
    final meanHidden =
        samples.map((s) => s.groundHiddenPercent).reduce((a, b) => a + b) /
        samples.length;
    if (meanHidden < clearThreshold) return WindowVerdict.clearViews;
    if (meanHidden < hiddenThreshold) return WindowVerdict.patchyClouds;
    final meanHigh =
        samples.map((s) => s.cloudHighPercent).reduce((a, b) => a + b) /
        samples.length;
    return meanHigh >= overcastHighThreshold
        ? WindowVerdict.overcast
        : WindowVerdict.cloudCarpet;
  }

  /// Merges consecutive samples with the same verdict into segments,
  /// dropping micro-segments (single sample surrounded by another verdict
  /// reads as noise, not weather).
  static List<WeatherSegment> segments(List<RouteCloudSample> samples) {
    if (samples.isEmpty) return const [];
    final raw = <WeatherSegment>[];
    var runStart = 0;
    var runVerdict = sampleVerdict(samples.first);
    for (var i = 1; i <= samples.length; i++) {
      final verdict = i < samples.length ? sampleVerdict(samples[i]) : null;
      if (verdict == runVerdict) continue;
      final startProgress = runStart == 0
          ? 0.0
          : (samples[runStart - 1].routeProgress +
                    samples[runStart].routeProgress) /
                2;
      final endProgress = i >= samples.length
          ? 1.0
          : (samples[i - 1].routeProgress + samples[i].routeProgress) / 2;
      raw.add(
        WeatherSegment(
          startProgress: startProgress,
          endProgress: endProgress,
          verdict: runVerdict,
        ),
      );
      runStart = i;
      if (verdict != null) runVerdict = verdict;
    }

    // Merge blips: a segment spanning a single sample gap joins its
    // larger neighbour.
    if (raw.length < 3) return raw;
    final merged = <WeatherSegment>[raw.first];
    for (var i = 1; i < raw.length; i++) {
      final current = raw[i];
      final previous = merged.last;
      final isBlip = current.length < 1.5 / samples.length && i < raw.length - 1;
      if (isBlip || current.verdict == previous.verdict) {
        merged[merged.length - 1] = WeatherSegment(
          startProgress: previous.startProgress,
          endProgress: current.endProgress,
          verdict: previous.verdict,
        );
      } else {
        merged.add(current);
      }
    }
    return merged;
  }
}
