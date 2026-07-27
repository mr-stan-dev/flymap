import 'package:equatable/equatable.dart';

/// Raw route measurements as they arrive from the backend / DB.
///
/// [cruiseMinutes] is airborne-at-cruise time (distance / cruise speed) — a
/// math intermediate, not a gate-to-gate duration. On the wire and in the DB
/// it is carried under the legacy key `approxDurationMinutes`; only mappers
/// should touch that name. For anything user-facing use
/// FlightRoute.durations.
class FlightRouteMetrics extends Equatable {
  static const int defaultCruiseSpeedKmh = 850;

  const FlightRouteMetrics({
    required this.greatCircleDistanceKm,
    required this.cruiseMinutes,
    this.actualDistanceKm,
    this.actualBlockMinutes,
  });

  factory FlightRouteMetrics.fromLegacyDistance(double distanceKm) {
    return FlightRouteMetrics(
      greatCircleDistanceKm: distanceKm,
      cruiseMinutes: estimateCruiseMinutes(distanceKm),
    );
  }

  final double greatCircleDistanceKm;
  final int cruiseMinutes;
  final double? actualDistanceKm;

  /// Recorded gate-to-gate minutes for historical (FR24) flights.
  final int? actualBlockMinutes;

  bool get isEmpty =>
      (!greatCircleDistanceKm.isFinite || greatCircleDistanceKm <= 0) &&
      cruiseMinutes <= 0 &&
      actualDistanceKm == null &&
      actualBlockMinutes == null;

  bool get hasActualTrack =>
      actualDistanceKm != null && actualBlockMinutes != null;

  double get effectiveDistanceKm =>
      _positiveFinite(actualDistanceKm) ?? greatCircleDistanceKm;

  int get displayDistanceKm => roundDistanceKmForDisplay(
    effectiveDistanceKm,
    isActual: _positiveFinite(actualDistanceKm) != null,
  );

  /// True cruise speed backed out of the cruise-only minutes. Never a block
  /// average — safe to feed into FlightDurationEstimatePolicy, which adds
  /// the ground/climb overhead itself.
  double? get cruiseSpeedKmh {
    if (cruiseMinutes <= 0) return null;
    if (!greatCircleDistanceKm.isFinite || greatCircleDistanceKm <= 0) {
      return null;
    }
    return greatCircleDistanceKm / (cruiseMinutes / 60.0);
  }

  FlightRouteMetrics copyWith({
    double? greatCircleDistanceKm,
    int? cruiseMinutes,
    double? actualDistanceKm,
    bool clearActualDistanceKm = false,
    int? actualBlockMinutes,
    bool clearActualBlockMinutes = false,
  }) {
    return FlightRouteMetrics(
      greatCircleDistanceKm:
          greatCircleDistanceKm ?? this.greatCircleDistanceKm,
      cruiseMinutes: cruiseMinutes ?? this.cruiseMinutes,
      actualDistanceKm: clearActualDistanceKm
          ? null
          : actualDistanceKm ?? this.actualDistanceKm,
      actualBlockMinutes: clearActualBlockMinutes
          ? null
          : actualBlockMinutes ?? this.actualBlockMinutes,
    );
  }

  static int estimateCruiseMinutes(double distanceKm) {
    if (!distanceKm.isFinite || distanceKm <= 0) return 0;
    final cruiseMinutes = (distanceKm * 60) / defaultCruiseSpeedKmh;
    return (cruiseMinutes / 5).round() * 5;
  }

  static int roundDistanceKmForDisplay(
    double distanceKm, {
    required bool isActual,
  }) {
    if (!distanceKm.isFinite || distanceKm <= 0) return 0;
    if (!isActual) return distanceKm.round();
    return ((distanceKm / 10).round() * 10).toInt();
  }

  static int roundDurationMinutesForDisplay(
    int minutes, {
    required bool isActual,
  }) {
    if (minutes <= 0) return 0;
    if (!isActual) return minutes;
    return (minutes / 5).round() * 5;
  }

  static double? _positiveFinite(double? value) {
    if (value == null || !value.isFinite || value <= 0) return null;
    return value;
  }

  @override
  List<Object?> get props => [
    greatCircleDistanceKm,
    cruiseMinutes,
    actualDistanceKm,
    actualBlockMinutes,
  ];
}
