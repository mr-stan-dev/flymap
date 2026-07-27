import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/mappers/flight_db_mapper.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('FlightDbMapper flightAccessTier', () {
    test('round-trip preserves pro tier', () {
      final mapper = FlightDbMapper();
      final flight = _flight(
        id: 'flight-1',
        flightAccessTier: Flight.accessTierPro,
      );

      final raw = mapper.toDb(flight);
      final restored = mapper.fromDb(raw);

      expect(restored.flightAccessTier, Flight.accessTierPro);
    });

    test('legacy map without key defaults to basic tier', () {
      final mapper = FlightDbMapper();
      final raw = mapper.toDb(
        _flight(id: 'flight-legacy', flightAccessTier: Flight.accessTierPro),
      );
      raw.remove(FlightDBKeys.flightAccessTier);

      final restored = mapper.fromDb(raw);

      expect(restored.flightAccessTier, Flight.accessTierBasic);
    });

    test('reads v2.0.2 flight records with legacy flightInfo shape', () {
      final mapper = FlightDbMapper();
      final raw = <String, dynamic>{
        FlightDBKeys.id: 'legacy-v202',
        FlightDBKeys.status: 'completed',
        FlightDBKeys.flightMaps: const <Map<String, dynamic>>[],
        FlightDBKeys.flightInfo: <String, dynamic>{
          'overview': 'Legacy overview',
          'poi': const <Map<String, dynamic>>[],
          'articles': const <Map<String, dynamic>>[],
          'routeRegions': const <Map<String, dynamic>>[],
          'routeTotalMinutes': 125,
          'routeCruiseSpeedKmh': 760,
        },
        FlightDBKeys.createdAt: '2026-01-01T00:00:00.000Z',
        FlightDBKeys.completedAt: '2026-01-02T00:00:00.000Z',
        FlightDBKeys.departure: _airportDb(
          name: 'A',
          city: 'City A',
          countryCode: 'US',
          lat: 10,
          lon: 10,
          iata: 'AAA',
          icao: 'AAAA',
        ),
        FlightDBKeys.arrival: _airportDb(
          name: 'B',
          city: 'City B',
          countryCode: 'US',
          lat: 20,
          lon: 20,
          iata: 'BBB',
          icao: 'BBBB',
        ),
        FlightDBKeys.waypoints: const [
          {'latitude': 10.0, 'longitude': 10.0},
          {'latitude': 20.0, 'longitude': 20.0},
        ],
        FlightDBKeys.corridor: const [
          {'latitude': 9.0, 'longitude': 9.0},
          {'latitude': 21.0, 'longitude': 9.0},
          {'latitude': 21.0, 'longitude': 21.0},
          {'latitude': 9.0, 'longitude': 21.0},
        ],
        FlightDBKeys.flightAccessTier: Flight.accessTierPro,
      };

      final restored = mapper.fromDb(raw);

      expect(restored.id, 'legacy-v202');
      expect(restored.status.rawValue, 'completed');
      expect(restored.flightAccessTier, Flight.accessTierPro);
      expect(restored.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(restored.completedAt, DateTime.parse('2026-01-02T00:00:00.000Z'));
      expect(restored.route.waypoints, hasLength(2));
      expect(restored.route.waypoints.first.timestamp, 0);
      expect(restored.route.corridorPolygons, hasLength(1));
      expect(restored.info.overview, 'Legacy overview');
      expect(restored.info.routeCruiseMinutes, 125);
      expect(restored.route.greatCircleDistanceKm, greaterThan(0));
    });
  });
}

Flight _flight({
  required String id,
  String flightAccessTier = Flight.accessTierBasic,
}) {
  return Flight(
    id: id,
    route: _route(),
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(
      createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
    ),
    flightAccessTier: flightAccessTier,
  );
}

FlightRoute _route() {
  const departure = Airport(
    name: 'A',
    city: 'City A',
    countryCode: 'US',
    latLon: LatLng(10, 10),
    iataCode: 'AAA',
    icaoCode: 'AAAA',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'B',
    city: 'City B',
    countryCode: 'US',
    latLon: LatLng(20, 20),
    iataCode: 'BBB',
    icaoCode: 'BBBB',
    wikipediaUrl: '',
  );
  return const FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(10, 10)),
      FlightWaypoint(latLon: LatLng(20, 20)),
    ],
    corridor: [LatLng(10, 10), LatLng(20, 10), LatLng(20, 20), LatLng(10, 20)],
  );
}

Map<String, dynamic> _airportDb({
  required String name,
  required String city,
  required String countryCode,
  required double lat,
  required double lon,
  required String iata,
  required String icao,
}) {
  return <String, dynamic>{
    'name': name,
    'city': city,
    'country': countryCode,
    'latitude': lat,
    'longitude': lon,
    'iata': iata,
    'icao': icao,
    'wiki': '',
  };
}
