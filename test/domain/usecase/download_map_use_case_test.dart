import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/usecase/download_map_use_case.dart';
import 'package:flymap/map_download_config.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const route = FlightRoute(
    departure: Airport(
      name: 'London Heathrow',
      city: 'London',
      countryCode: 'GB',
      latLon: LatLng(51.47, -0.45),
      iataCode: 'LHR',
      icaoCode: 'EGLL',
      wikipediaUrl: '',
    ),
    arrival: Airport(
      name: 'Munich Airport',
      city: 'Munich',
      countryCode: 'DE',
      latLon: LatLng(48.35, 11.79),
      iataCode: 'MUC',
      icaoCode: 'EDDM',
      wikipediaUrl: '',
    ),
    waypoints: [
      FlightWaypoint(latLon: LatLng(51.47, -0.45)),
      FlightWaypoint(latLon: LatLng(48.35, 11.79)),
    ],
    corridor: [LatLng(51.47, -0.45), LatLng(48.35, 11.79)],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1487.5,
      approxDurationMinutes: 105,
    ),
  );

  group('DownloadMapUseCase.mapFileName', () {
    test('is unique per flight so same-route flights never share a file', () {
      final a = DownloadMapUseCase.mapFileName(route: route, flightId: 'id-a');
      final b = DownloadMapUseCase.mapFileName(route: route, flightId: 'id-b');
      expect(a, isNot(equals(b)));
    });

    test('keeps the route code and layer for debuggability', () {
      final name = DownloadMapUseCase.mapFileName(
        route: route,
        flightId: 'id-a',
      );
      expect(name, contains(route.routeCode));
      expect(name, contains('id-a'));
      expect(name, endsWith(MapDownloadConfig.mapLayerId));
    });
  });
}
