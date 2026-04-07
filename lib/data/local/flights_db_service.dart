import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/logger.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';
import 'mappers/flight_db_mapper.dart';

class FlightsDBService {
  final AppDatabase _database;
  final FlightDbMapper _flightMapper;
  final _logger = Logger('FlightsLocalDBService');

  FlightsDBService({
    required AppDatabase database,
    required FlightDbMapper flightMapper,
  }) : _database = database,
       _flightMapper = flightMapper;

  Future<String> insertFlight(Flight flight) async {
    return saveOrUpdateFlight(flight);
  }

  Future<String> saveOrUpdateFlight(Flight flight) async {
    final key = flight.id;
    _logger.log('Saving flight: ${flight.id}');
    final map = _flightMapper.toDb(flight);
    await _database.flightsStore.record(key).put(_database.database, map);
    return key;
  }

  Future<bool> updateFlightInfo(String flightId, FlightInfo info) async {
    final existing = await getFlightById(flightId);
    if (existing == null) return false;
    final updated = Flight(
      id: existing.id,
      route: existing.route,
      maps: existing.maps,
      info: info,
      createdAt: existing.createdAt,
    );
    await saveOrUpdateFlight(updated);
    return true;
  }

  Future<Flight?> getFlightById(String flightId) async {
    final map = await _database.flightsStore
        .record(flightId)
        .get(_database.database);
    if (map == null) return null;
    return _flightMapper.fromDb(map);
  }

  Future<List<Flight>> getAllFlights() async {
    final records = await _database.flightsStore.find(_database.database);
    return records.map((record) => _flightMapper.fromDb(record.value)).toList();
  }

  Future<List<Flight>> getRecentFlights({int limit = 10}) async {
    final records = await _database.flightsStore.find(
      _database.database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)], limit: limit),
    );
    return records.map((record) => _flightMapper.fromDb(record.value)).toList();
  }

  Future<bool> deleteFlightRecord(String flightId) async {
    final exists =
        await _database.flightsStore.record(flightId).get(_database.database) !=
        null;
    if (!exists) return false;
    await _database.flightsStore.record(flightId).delete(_database.database);
    return true;
  }
}
