import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/router/app_router.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('flightRouteRedirectTarget guards the /flight route', () {
    test('redirects home when extra is null (the crash case)', () {
      expect(AppRouter.flightRouteRedirectTarget(null), AppRouter.homeRoute);
    });

    test('redirects home when extra is the wrong type', () {
      expect(AppRouter.flightRouteRedirectTarget('nope'), AppRouter.homeRoute);
      expect(AppRouter.flightRouteRedirectTarget(42), AppRouter.homeRoute);
    });

    test('redirects home when the map carries no Flight', () {
      expect(
        AppRouter.flightRouteRedirectTarget(
          <String, dynamic>{'openWeather': true},
        ),
        AppRouter.homeRoute,
      );
      expect(
        AppRouter.flightRouteRedirectTarget(<String, dynamic>{'flight': null}),
        AppRouter.homeRoute,
      );
      expect(
        AppRouter.flightRouteRedirectTarget(<String, dynamic>{'flight': 'x'}),
        AppRouter.homeRoute,
      );
    });

    test('proceeds (returns null) when a Flight is present', () {
      expect(
        AppRouter.flightRouteRedirectTarget(<String, dynamic>{
          'flight': _flight(),
        }),
        isNull,
      );
    });
  });
}

Flight _flight() {
  const airport = Airport(
    name: 'A',
    city: 'A',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  const route = FlightRoute(
    departure: airport,
    arrival: airport,
    waypoints: [FlightWaypoint(latLon: LatLng(51.47, -0.45))],
    corridor: [LatLng(51.47, -0.45)],
    metrics: FlightRouteMetrics(greatCircleDistanceKm: 1, cruiseMinutes: 1),
  );
  return Flight(
    id: 'f1',
    route: route,
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 1, 1)),
    status: FlightStatus.inProgress,
  );
}
