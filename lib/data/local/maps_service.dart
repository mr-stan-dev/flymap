import 'package:sembast/sembast_io.dart';
import 'package:flymap/entity/map/flight_map.dart';
import 'app_database.dart';

class MapsService {
  final AppDatabase _database;

  MapsService({required AppDatabase database}) : _database = database;

  /// Insert or update map data for a flight
  Future<void> insertMapData(FlightMap mapData) async {
    final key = mapData
        .layer; // we use layer as the unique key (equals flightId for now)
    await _database.mapsStore
        .record(key)
        .put(_database.database, mapData.toMap());
  }

  /// Get map data for a specific flight and map type (keyed by "flightId_mapType")
  Future<FlightMap?> getMapData(String flightId, String mapType) async {
    final key = '${flightId}_$mapType';
    final map = await _database.mapsStore.record(key).get(_database.database);
    if (map == null) return null;
    return FlightMap.fromMap(map);
  }

  /// Get all map data for a flight (key equals flightId or starts with it)
  Future<List<FlightMap>> getFlightMaps(String flightId) async {
    final records = await _database.mapsStore.find(_database.database);
    return records
        .where((record) => record.key.toString().startsWith(flightId))
        .map((record) => FlightMap.fromMap(record.value))
        .toList();
  }

  /// Get all map data
  Future<List<FlightMap>> getAllMaps() async {
    final records = await _database.mapsStore.find(_database.database);
    return records.map((record) => FlightMap.fromMap(record.value)).toList();
  }

  /// Get total downloaded maps count
  Future<int> getTotalDownloadedMaps() async {
    final records = await _database.mapsStore.find(_database.database);
    return records.length;
  }

  /// Get total map size in bytes
  Future<int> getTotalMapSize() async {
    final records = await _database.mapsStore.find(_database.database);
    int totalSize = 0;
    for (final record in records) {
      totalSize += record.value['sizeBytes'] as int? ?? 0;
    }
    return totalSize;
  }

  /// Delete map data for a specific flight and map type
  Future<bool> deleteMapData(String flightId, String mapType) async {
    final key = '${flightId}_$mapType';
    final existing = await _database.mapsStore
        .record(key)
        .get(_database.database);
    if (existing == null) return false;
    await _database.mapsStore.record(key).delete(_database.database);
    return true;
  }

  /// Delete all map data for a flight
  Future<void> deleteFlightMaps(String flightId) async {
    final records = await _database.mapsStore.find(_database.database);
    for (final record in records) {
      if (record.key.toString().startsWith(flightId)) {
        await _database.mapsStore.record(record.key).delete(_database.database);
      }
    }
  }

  /// Update map data
  Future<bool> updateMapData(FlightMap mapData) async {
    final key = mapData.layer;
    final existing = await _database.mapsStore
        .record(key)
        .get(_database.database);
    if (existing == null) return false;

    await _database.mapsStore
        .record(key)
        .put(_database.database, mapData.toMap());
    return true;
  }

  /// Get map data by file path
  Future<FlightMap?> getMapDataByPath(String filePath) async {
    final records = await _database.mapsStore.find(
      _database.database,
      finder: Finder(filter: Filter.equals('filePath', filePath)),
    );

    if (records.isEmpty) return null;
    return FlightMap.fromMap(records.first.value);
  }

  /// Get recent maps
  Future<List<FlightMap>> getRecentMaps({int limit = 10}) async {
    final records = await _database.mapsStore.find(
      _database.database,
      finder: Finder(
        sortOrders: [SortOrder('downloadedAt', false)],
        limit: limit,
      ),
    );
    return records.map((record) => FlightMap.fromMap(record.value)).toList();
  }

  /// Get maps by type (keys that end with "_mapType")
  Future<List<FlightMap>> getMapsByType(String mapType) async {
    final records = await _database.mapsStore.find(_database.database);
    return records
        .where((record) => record.key.toString().endsWith('_$mapType'))
        .map((record) => FlightMap.fromMap(record.value))
        .toList();
  }
}
