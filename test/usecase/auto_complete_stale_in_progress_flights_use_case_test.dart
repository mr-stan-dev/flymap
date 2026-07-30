import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/usecase/auto_complete_stale_in_progress_flights_use_case.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('AutoCompleteStaleInProgressFlightsUseCase', () {
    test('completes only in-progress flights older than max age', () async {
      final now = DateTime.utc(2026, 5, 9, 12);
      final repository = _FakeFlightRepository(
        flights: [
          _flight(
            id: 'stale',
            status: FlightStatus.inProgress,
            createdAt: now.subtract(const Duration(days: 3)),
            inProgressAt: now.subtract(const Duration(hours: 30)),
          ),
          _flight(
            id: 'recent',
            status: FlightStatus.inProgress,
            createdAt: now.subtract(const Duration(days: 1)),
            inProgressAt: now.subtract(const Duration(hours: 3)),
          ),
          _flight(
            id: 'upcoming',
            status: FlightStatus.upcoming,
            createdAt: now.subtract(const Duration(days: 5)),
          ),
        ],
      );
      final useCase = AutoCompleteStaleInProgressFlightsUseCase(
        repository: repository,
      );

      final updated = await useCase.call(now: now);

      expect(updated, 1);
      expect(repository.updates, hasLength(1));
      expect(repository.updates.single.flightId, 'stale');
      expect(repository.updates.single.status, FlightStatus.completed);
      expect(repository.updates.single.completedAt, now);
    });

    test('falls back to createdAt when inProgressAt is missing', () async {
      final now = DateTime.utc(2026, 5, 9, 12);
      final repository = _FakeFlightRepository(
        flights: [
          _flight(
            id: 'legacy-stale',
            status: FlightStatus.inProgress,
            createdAt: now.subtract(const Duration(hours: 50)),
          ),
        ],
      );
      final useCase = AutoCompleteStaleInProgressFlightsUseCase(
        repository: repository,
      );

      final updated = await useCase.call(now: now);

      expect(updated, 1);
      expect(repository.updates.single.flightId, 'legacy-stale');
    });
  });
}

class _FakeFlightRepository implements FlightRepository {
  @override
  Future<bool> updateFlightAccessTier({
    required String flightId,
    required String accessTier,
  }) async => true;

  _FakeFlightRepository({required this.flights});

  final List<Flight> flights;
  final List<_FlightStatusUpdate> updates = <_FlightStatusUpdate>[];

  @override
  Future<List<Flight>> getAllFlights() async => flights;

  @override
  Future<bool> updateFlightStatus({
    required String flightId,
    required FlightStatus status,
    DateTime? completedAt,
  }) async {
    updates.add(
      _FlightStatusUpdate(
        flightId: flightId,
        status: status,
        completedAt: completedAt,
      ),
    );
    return true;
  }

  @override
  Future<Flight?> getFlightById(String flightId) async => null;

  @override
  Future<String> insertFlight(Flight flight) async => flight.id;

  @override
  Future<String> saveOrUpdateFlight(Flight flight) async => flight.id;

  @override
  Future<int> getTotalDownloadedMaps() async => 0;

  @override
  Future<double> getTotalFlightDistanceKm() async => 0;

  @override
  Future<int> getTotalFlights() async => 0;

  @override
  Future<int> getTotalMapSize() async => 0;

  @override
  Future<bool> updateFlightInfo({
    required String flightId,
    required FlightInfo info,
  }) async => true;
}

class _FlightStatusUpdate {
  const _FlightStatusUpdate({
    required this.flightId,
    required this.status,
    required this.completedAt,
  });

  final String flightId;
  final FlightStatus status;
  final DateTime? completedAt;
}

Flight _flight({
  required String id,
  required FlightStatus status,
  required DateTime createdAt,
  DateTime? inProgressAt,
}) {
  const departure = Airport(
    name: 'A',
    city: 'A',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'B',
    city: 'B',
    countryCode: 'DE',
    latLon: LatLng(48.35, 11.79),
    iataCode: 'MUC',
    icaoCode: 'EDDM',
    wikipediaUrl: '',
  );
  const route = FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(51.47, -0.45)),
      FlightWaypoint(latLon: LatLng(48.35, 11.79)),
    ],
    corridor: [
      LatLng(51.47, -0.45),
      LatLng(48.35, -0.45),
      LatLng(48.35, 11.79),
    ],
  );
  return Flight(
    id: id,
    route: route,
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(
      createdAt: createdAt,
      inProgressAt: inProgressAt,
    ),
    status: status,
  );
}
