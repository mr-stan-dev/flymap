import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Surface forecast at one airport around the scheduled local time.
class AirportWeather extends Equatable {
  const AirportWeather({
    required this.timeUtc,
    required this.utcOffsetMinutes,
    this.temperatureC,
    this.windSpeedMs,
    this.precipitationMm,
    this.cloudCoverPercent,
    this.symbolCode,
  });

  /// Forecast instant (UTC) this entry describes.
  final DateTime timeUtc;

  /// Offset for displaying the airport's wall-clock time; 0 when unknown.
  final int utcOffsetMinutes;
  final double? temperatureC;
  final double? windSpeedMs;
  final double? precipitationMm;
  final double? cloudCoverPercent;

  /// MET Norway symbol code (e.g. "partlycloudy_day") — maps to an icon.
  final String? symbolCode;

  DateTime get timeLocal =>
      timeUtc.add(Duration(minutes: utcOffsetMinutes));

  @override
  List<Object?> get props => [
    timeUtc,
    utcOffsetMinutes,
    temperatureC,
    windSpeedMs,
    precipitationMm,
    cloudCoverPercent,
    symbolCode,
  ];
}

/// Cloud state at one instant — one entry of a sample point's timeline.
class CloudTimeSlice extends Equatable {
  const CloudTimeSlice({
    required this.timeUtc,
    required this.cloudLowPercent,
    required this.cloudMidPercent,
    required this.cloudHighPercent,
    this.precipitationMm = 0,
  });

  final DateTime timeUtc;
  final double cloudLowPercent;
  final double cloudMidPercent;
  final double cloudHighPercent;

  /// Expected precipitation (mm, next hour) at this instant.
  final double precipitationMm;

  double get groundHiddenPercent =>
      (cloudLowPercent + cloudMidPercent).clamp(0, 100);

  @override
  List<Object?> get props => [
    timeUtc,
    cloudLowPercent,
    cloudMidPercent,
    cloudHighPercent,
    precipitationMm,
  ];
}

/// Cloud state at one route point at the moment the plane is overhead.
class RouteCloudSample extends Equatable {
  const RouteCloudSample({
    required this.routeProgress,
    required this.latLon,
    required this.timeUtc,
    required this.cloudLowPercent,
    required this.cloudMidPercent,
    required this.cloudHighPercent,
    this.precipitationMm,
    this.timeline = const <CloudTimeSlice>[],
  });

  /// 0..1 along the route (departure -> arrival).
  final double routeProgress;
  final LatLng latLon;

  /// Overhead time: STD + routeProgress * block time.
  final DateTime timeUtc;
  final double cloudLowPercent;
  final double cloudMidPercent;
  final double cloudHighPercent;
  final double? precipitationMm;

  /// This point's cloud state across the whole flight window (already part
  /// of the single provider response — no extra requests). Lets the map
  /// animate cloud evolution as the plane progresses; may be empty.
  final List<CloudTimeSlice> timeline;

  /// Share of ground hidden from a window seat: cruise sits above the
  /// low/mid bands, so those hide the ground; high cirrus is a thin veil.
  double get groundHiddenPercent =>
      (cloudLowPercent + cloudMidPercent).clamp(0, 100);

  /// Linearly interpolated hidden-ground share at [timeUtc]; falls back to
  /// the overhead value when the timeline is empty or out of range.
  double hiddenAt(DateTime time) => _interpolate(
    time,
    (slice) => slice.groundHiddenPercent,
    groundHiddenPercent,
  );

  /// Linearly interpolated high-cirrus share at [timeUtc].
  double highAt(DateTime time) =>
      _interpolate(time, (slice) => slice.cloudHighPercent, cloudHighPercent);

  /// Linearly interpolated precipitation (mm/h) at [timeUtc].
  double rainAt(DateTime time) => _interpolate(
    time,
    (slice) => slice.precipitationMm,
    precipitationMm ?? 0,
  );

  double _interpolate(
    DateTime time,
    double Function(CloudTimeSlice) value,
    double fallback,
  ) {
    if (timeline.isEmpty) return fallback;
    if (!time.isAfter(timeline.first.timeUtc)) return value(timeline.first);
    if (!time.isBefore(timeline.last.timeUtc)) return value(timeline.last);
    for (var i = 1; i < timeline.length; i++) {
      final next = timeline[i];
      if (time.isAfter(next.timeUtc)) continue;
      final prev = timeline[i - 1];
      final span = next.timeUtc.difference(prev.timeUtc).inSeconds;
      if (span <= 0) return value(next);
      final t = time.difference(prev.timeUtc).inSeconds / span;
      return value(prev) + (value(next) - value(prev)) * t;
    }
    return fallback;
  }

  @override
  List<Object?> get props => [
    routeProgress,
    latLon,
    timeUtc,
    cloudLowPercent,
    cloudMidPercent,
    cloudHighPercent,
    precipitationMm,
    timeline,
  ];
}

/// The whole fetched weather picture for one flight.
class FlightWeather extends Equatable {
  const FlightWeather({
    required this.departure,
    required this.arrival,
    required this.samples,
    this.areaSamples = const <RouteCloudSample>[],
    required this.fetchedAt,
    required this.isTimeEstimated,
  });

  final AirportWeather departure;
  final AirportWeather arrival;

  /// Ordered by [RouteCloudSample.routeProgress].
  final List<RouteCloudSample> samples;

  /// Sparse grid over the rest of the map card, so clouds cover the whole
  /// picture instead of a corridor-only band. Each carries the overhead
  /// time of its nearest route point (and its own timeline). Not used by
  /// the verdict — decoration honesty only.
  final List<RouteCloudSample> areaSamples;
  final DateTime fetchedAt;

  /// True when no scheduled departure time was known and overhead times are
  /// midday/now estimates — the UI shows an "estimate" badge.
  final bool isTimeEstimated;

  @override
  List<Object?> get props => [
    departure,
    arrival,
    samples,
    areaSamples,
    fetchedAt,
    isTimeEstimated,
  ];
}
