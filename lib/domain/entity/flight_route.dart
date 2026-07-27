import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_durations.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/policy/flight_duration_estimate_policy.dart';
import 'package:flymap/domain/policy/domestic_route_policy.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:latlong2/latlong.dart';

class FlightRoute extends Equatable {
  final Airport departure;
  final Airport arrival;
  final FlightRouteSource source;
  final List<FlightWaypoint> waypoints;
  final List<LatLng> corridor;
  final List<List<LatLng>> corridorPolygons;
  final FlightRouteMetrics metrics;
  final double? legacyDistanceInKm;

  const FlightRoute({
    required this.departure,
    required this.arrival,
    this.source = FlightRouteSource.greatCircle,
    required this.waypoints,
    required this.corridor,
    this.corridorPolygons = const [],
    this.metrics = const FlightRouteMetrics(
      greatCircleDistanceKm: 0,
      cruiseMinutes: 0,
    ),
    @Deprecated('Use metrics instead') double? distanceInKm,
  }) : legacyDistanceInKm = distanceInKm;

  String get routeCode => '${departure.primaryCode}_${arrival.primaryCode}';

  bool get isDomestic => DomesticRoutePolicy.isDomestic(
    originCountryCode: departure.countryCode,
    destinationCountryCode: arrival.countryCode,
  );

  double get primaryDistanceKm {
    if (isHistoricalTrack) {
      return (actualDistanceKm != null && actualDistanceKm! > 0)
          ? actualDistanceKm!
          : greatCircleDistanceKm;
    }
    return greatCircleDistanceKm;
  }

  double get distanceInKm =>
      primaryDistanceKm > 0 ? primaryDistanceKm : (legacyDistanceInKm ?? 0);

  double get greatCircleDistanceKm => metrics.greatCircleDistanceKm > 0
      ? metrics.greatCircleDistanceKm
      : (legacyDistanceInKm ?? 0);

  double? get actualDistanceKm => metrics.actualDistanceKm;

  /// The single entry point for flight durations; see FlightDurations for
  /// which value to use where.
  FlightDurations get durations {
    final cruiseSpeedKmh =
        metrics.cruiseSpeedKmh?.round() ??
        FlightRouteMetrics.defaultCruiseSpeedKmh;
    return FlightDurations(
      cruiseMinutes: metrics.cruiseMinutes > 0
          ? metrics.cruiseMinutes
          : FlightRouteMetrics.estimateCruiseMinutes(distanceInKm),
      estimatedBlockMinutes: FlightDurationEstimatePolicy.estimateBlockMinutes(
        distanceKm: greatCircleDistanceKm,
        cruiseSpeedKmh: cruiseSpeedKmh,
        roundToMinutes: 5,
      ),
      actualBlockMinutes: isHistoricalTrack ? metrics.actualBlockMinutes : null,
    );
  }

  int get displayPrimaryDistanceKm =>
      FlightRouteMetrics.roundDistanceKmForDisplay(
        primaryDistanceKm > 0 ? primaryDistanceKm : (legacyDistanceInKm ?? 0),
        isActual:
            isHistoricalTrack &&
            actualDistanceKm != null &&
            actualDistanceKm! > 0,
      );

  int get displayDistanceKm => displayPrimaryDistanceKm;

  bool get isHistoricalTrack => source == FlightRouteSource.fr24Historical;

  List<LatLng> get waypointLatLngs =>
      waypoints.map((waypoint) => waypoint.latLon).toList(growable: false);

  List<List<LatLng>> get effectiveCorridorPolygons =>
      corridorPolygons.isNotEmpty ? corridorPolygons : [corridor];

  @override
  List<Object?> get props => [
    departure,
    arrival,
    source,
    waypoints,
    corridor,
    corridorPolygons,
    metrics,
    legacyDistanceInKm,
  ];
}
