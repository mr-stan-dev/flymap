import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';

/// The three duration concepts for a flight, in one place.
///
/// - [cruiseMinutes]: airborne time at cruise speed (distance / cruise speed).
///   A math intermediate for timeline spacing — never show it as the flight
///   duration.
/// - [estimatedBlockMinutes]: estimated gate-to-gate time (cruise plus
///   taxi/climb/descent overhead, see FlightDurationEstimatePolicy).
/// - [actualBlockMinutes]: recorded gate-to-gate time for historical (FR24)
///   flights.
///
/// UI surfaces should read [blockMinutes] / [displayBlockMinutes].
class FlightDurations extends Equatable {
  const FlightDurations({
    required this.cruiseMinutes,
    required this.estimatedBlockMinutes,
    this.actualBlockMinutes,
  });

  final int cruiseMinutes;
  final int estimatedBlockMinutes;
  final int? actualBlockMinutes;

  bool get isActual => (actualBlockMinutes ?? 0) > 0;

  /// Gate-to-gate duration: actual when recorded, estimated otherwise.
  int get blockMinutes =>
      isActual ? actualBlockMinutes! : estimatedBlockMinutes;

  int get displayBlockMinutes =>
      FlightRouteMetrics.roundDurationMinutesForDisplay(
        blockMinutes,
        isActual: isActual,
      );

  @override
  List<Object?> get props => [
    cruiseMinutes,
    estimatedBlockMinutes,
    actualBlockMinutes,
  ];
}
