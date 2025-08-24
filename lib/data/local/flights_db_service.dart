import 'dart:io';

import 'package:flymap/entity/flight.dart';
import 'package:flymap/logger.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';
import 'mappers/flight_db_mapper.dart';
import 'mappers/flight_map_mapper.dart';

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
    final key = flight.id;
    _logger.log('Saving new flight: ${flight.id}');
    final map = _flightMapper.toDb(flight);
    await _database.flightsStore.record(key).put(_database.database, map);
    return key;
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

  Future<bool> deleteFlight(String flightId) async {
    final existing = await _database.flightsStore
        .record(flightId)
        .get(_database.database);
    if (existing == null) return false;

    await _deleteMapFiles(existing);

    await _database.flightsStore.record(flightId).delete(_database.database);
    return true;
  }

  void _deleteSidecars(String mainPath) {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('$mainPath$suffix');
      if (sidecar.existsSync()) {
        try {
          sidecar.deleteSync();
          _logger.log('Deleted sidecar file: ${sidecar.path}');
        } catch (e) {
          _logger.error('Failed to delete sidecar ${sidecar.path}: $e');
        }
      }
    }
  }

  Future<void> _deleteMapFiles(dynamic flight) async {
    // Remove associated map files from disk if present
    try {
      final map = (flight as Map);
      final dynamic mapsRaw = map[FlightDBKeys.flightMaps];
      _logger.log('Deleted map list: ${mapsRaw is List}');
      if (mapsRaw is List) {
        for (final m in mapsRaw.whereType<Map>()) {
          final filePath = (m[FlightMapDBKeys.filePath])?.toString();
          _logger.log('Deleted map filePath: $filePath');
          if (filePath != null && filePath.isNotEmpty) {
            final f = File(filePath);
            _logger.log('Deleted map existsSync: ${f.existsSync()}');
            if (f.existsSync()) {
              try {
                f.deleteSync();
                _logger.log('Deleted map file: $filePath');
              } catch (e) {
                _logger.error('Failed to delete $filePath: $e');
              }
            }
            _deleteSidecars(filePath);
          }
        }
      }
    } catch (e) {
      _logger.error('Error deleting map files for flight $flight: $e');
    }
  }
}
