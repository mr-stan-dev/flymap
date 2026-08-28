import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/local/mappers/flight_db_mapper.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_map.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/usecase/restore_flight_use_case.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  late Database database;
  late FlightsDBService service;
  late RestoreFlightUseCase useCase;

  setUp(() async {
    database = await newDatabaseFactoryMemory().openDatabase(
      'restore_flight_test.db',
    );
    service = FlightsDBService(
      database: AppDatabase.test(database: database),
      flightMapper: FlightDbMapper(),
    );
    useCase = RestoreFlightUseCase(
      repository: FlightRepository(service: service),
    );
  });

  tearDown(() => database.close());

  test(
    'restores a completed flight to Upcoming and keeps its offline map',
    () async {
      final flight = _completedFlight();
      await service.saveOrUpdateFlight(flight);

      final restoredSuccessfully = await useCase(flightId: flight.id);

      expect(restoredSuccessfully, isTrue);
      final restored = await service.getFlightById(flight.id);
      expect(restored, isNotNull);
      expect(restored!.status, FlightStatus.upcoming);
      expect(restored.inProgressAt, isNull);
      expect(restored.completedAt, isNull);
      expect(restored.maps, flight.maps);
    },
  );

  test('returns false when the completed flight no longer exists', () async {
    expect(await useCase(flightId: 'missing'), isFalse);
  });
}

Flight _completedFlight() {
  final createdAt = DateTime.utc(2026, 8, 25, 10);
  const departure = Airport(
    name: 'London Heathrow',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Munich Airport',
    city: 'Munich',
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
    id: 'completed-flight',
    route: route,
    maps: [
      FlightMap(
        layer: 'ofm_vector',
        sizeBytes: 1024,
        downloadedAt: createdAt,
        filePath: 'completed-flight.mbtiles',
      ),
    ],
    routeInsights: FlightInfo.empty.routeInsights,
    timestamp: FlightTimestamp(
      createdAt: createdAt,
      inProgressAt: createdAt.add(const Duration(hours: 1)),
      completedAt: createdAt.add(const Duration(hours: 25)),
    ),
    status: FlightStatus.completed,
  );
}
