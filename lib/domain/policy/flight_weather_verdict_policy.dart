import 'package:flymap/domain/entity/flight_schedule.dart';
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

/// A contiguous stretch of the route with meaningful precipitation.
class RainRun {
  const RainRun({required this.startProgress, required this.endProgress});

  final double startProgress;
  final double endProgress;

  double get midProgress => (startProgress + endProgress) / 2;
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

  /// Forecasts degrade quickly past a week out — beyond this the step
  /// explains instead of fetching anything.
  static const int reliableForecastDaysAhead = 7;

  /// True when the flight is too far in the future for a dependable
  /// forecast. Uses the scheduled departure when known, otherwise the
  /// calendar travel date; a null schedule (no date picked) is never
  /// "too far" — the fetch falls back to today's estimate as before.
  static bool isBeyondForecastHorizon(
    FlightSchedule? schedule, {
    required DateTime now,
  }) {
    if (schedule == null) return false;
    const horizon = Duration(days: reliableForecastDaysAhead);
    final departureUtc = schedule.departure?.utc;
    if (departureUtc != null) {
      return departureUtc.difference(now.toUtc()) > horizon;
    }
    final travel = schedule.travelDate;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(
          travel.year,
          travel.month,
          travel.day,
        ).difference(today) >
        horizon;
  }

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

  /// Below this the forecast precipitation is treated as dry noise.
  static const double rainThresholdMm = 0.5;

  /// Contiguous stretches where the overhead-time precipitation reaches
  /// [rainThresholdMm] — the expectation line calls these out.
  static List<RainRun> rainRuns(List<RouteCloudSample> samples) {
    final runs = <RainRun>[];
    double? runStart;
    double lastProgress = 0;
    for (final sample in samples) {
      final rainy = (sample.precipitationMm ?? 0) >= rainThresholdMm;
      if (rainy) {
        runStart ??= sample.routeProgress;
        lastProgress = sample.routeProgress;
      } else if (runStart != null) {
        runs.add(RainRun(startProgress: runStart, endProgress: lastProgress));
        runStart = null;
      }
    }
    if (runStart != null) {
      runs.add(RainRun(startProgress: runStart, endProgress: lastProgress));
    }
    return runs;
  }

  /// Wind speed (m/s) at or below which airport conditions read as calm.
  static const double calmWindThresholdMs = 5;

  /// Good-news-only signal for the verdict banner: the ride looks calm and the
  /// view looks clear. A deliberately conservative proxy built from the data we
  /// actually fetch — MET Norway `/complete` has no CAPE or winds-aloft, so
  /// this is honestly "calm & clear", not a turbulence forecast: both airports
  /// calm and dry, no precipitation along the corridor, and an overall
  /// clear-views verdict. Any missing input returns false — silence beats a
  /// wrong "smooth skies".
  static bool isCalmAndClear(FlightWeather weather) {
    final samples = weather.samples;
    if (samples.isEmpty) return false;
    if (overallVerdict(samples) != WindowVerdict.clearViews) return false;
    if (rainRuns(samples).isNotEmpty) return false;
    for (final airport in [weather.departure, weather.arrival]) {
      final wind = airport.windSpeedMs;
      if (wind == null || wind > calmWindThresholdMs) return false;
      if ((airport.precipitationMm ?? 0) >= rainThresholdMm) return false;
    }
    return true;
  }
}
