import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/mappers/flight_weather_db_mapper.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/logger.dart';
import 'package:sembast/sembast.dart';

/// Last fetched forecast per saved flight — what the weather screen shows
/// in airplane mode. Updated on every successful fetch; deleted with the
/// flight.
class FlightWeatherStore {
  FlightWeatherStore({AppDatabase? database, FlightWeatherDbMapper? mapper})
    : _database = database ?? AppDatabase.instance,
      _mapper = mapper ?? const FlightWeatherDbMapper();

  final AppDatabase _database;
  final FlightWeatherDbMapper _mapper;
  static const _logger = Logger('FlightWeatherStore');

  Future<void> save(String flightId, FlightWeather weather) async {
    try {
      await _database.flightWeatherStore
          .record(flightId)
          .put(_database.database, _mapper.toDb(weather));
    } catch (e) {
      // Persistence is best-effort: a failed write must never break the
      // live forecast the user is looking at.
      _logger.error('save failed for $flightId: $e');
    }
  }

  Future<FlightWeather?> load(String flightId) async {
    try {
      final map = await _database.flightWeatherStore
          .record(flightId)
          .get(_database.database);
      if (map == null) return null;
      return _mapper.fromDb(Map<String, dynamic>.from(map));
    } catch (e) {
      _logger.error('load failed for $flightId: $e');
      return null;
    }
  }

  Future<void> delete(String flightId) async {
    try {
      await _database.flightWeatherStore
          .record(flightId)
          .delete(_database.database);
    } catch (e) {
      _logger.error('delete failed for $flightId: $e');
    }
  }
}
