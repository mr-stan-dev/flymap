import 'package:flymap/logger.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';
import 'mappers/flight_db_mapper.dart';
import 'package:flymap/entity/flight.dart';

class FlightsLocalDBService {
  final AppDatabase _database;
  final FlightDbMapper _flightMapper;
  final _logger = Logger('FlightsLocalDBService');

  FlightsLocalDBService({
    required AppDatabase database,
    required FlightDbMapper flightMapper,
  }) : _database = database,
       _flightMapper = flightMapper;

  /// Insert a new flight
  Future<String> insertFlight(Flight flight) async {
    final key = flight.id;
    _logger.log('Saving new flight info: ${flight.info}');
    final map = _flightMapper.toDb(flight);
    _logger.log('Saving new flight: ${map['flightInfo']}');
    await _database.flightsStore.record(key).put(_database.database, map);
    return key;
  }

  /// Get flight by ID
  Future<Flight?> getFlightById(String flightId) async {
    final map = await _database.flightsStore
        .record(flightId)
        .get(_database.database);
    if (map == null) return null;
    return _flightMapper.fromDb(map);
  }

  /// Get all flights
  Future<List<Flight>> getAllFlights() async {
    final records = await _database.flightsStore.find(_database.database);
    return records.map((record) => _flightMapper.fromDb(record.value)).toList();
  }

  /// Get recent flights
  Future<List<Flight>> getRecentFlights({int limit = 10}) async {
    final records = await _database.flightsStore.find(
      _database.database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)], limit: limit),
    );
    return records.map((record) => _flightMapper.fromDb(record.value)).toList();
  }

  /// Delete flight by ID
  Future<bool> deleteFlight(String flightId) async {
    final existing = await _database.flightsStore
        .record(flightId)
        .get(_database.database);
    if (existing == null) return false;

    await _database.flightsStore.record(flightId).delete(_database.database);
    return true;
  }
}
