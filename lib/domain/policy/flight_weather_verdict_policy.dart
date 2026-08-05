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

/// Turns route cloud samples into the overall window verdict. Pure math, no
/// I/O.
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

  /// True when the flight's calendar date is unambiguously before today.
  /// Same-day flights stay eligible because an approximate departure is
  /// clamped forward by the fetch use case, and a scheduled flight may still
  /// be in progress after its STD.
  static bool isInPast(FlightSchedule? schedule, {required DateTime now}) {
    if (schedule == null) return false;
    final travel = schedule.travelDate;
    final travelDay = DateTime(travel.year, travel.month, travel.day);
    final today = DateTime(now.year, now.month, now.day);
    return travelDay.isBefore(today);
  }

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
    return DateTime(travel.year, travel.month, travel.day).difference(today) >
        horizon;
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
}
