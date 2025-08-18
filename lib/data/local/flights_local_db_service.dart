import 'package:flymap/data/local/flight_info_mapper.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/map/flight_map.dart';
import 'package:flymap/logger.dart';
import 'package:latlong2/latlong.dart';
import 'package:sembast/sembast_io.dart';

import 'app_database.dart';

class FlightsLocalDBService {
  final AppDatabase _database;
  final FlightInfoMapper _flightInfoMapper;
  final _logger = Logger('FlightsLocalDBService');

  FlightsLocalDBService({
    required AppDatabase database,
    required FlightInfoMapper flightInfoMapper,
  }) : _database = database,
       _flightInfoMapper = flightInfoMapper;

  /// Convert Flight entity to Map for storage
  Map<String, dynamic> _flightToMap(Flight flight) {
    return {
      'id': flight.id,

      // Departure info
      'departureAirportCode': flight.departure.code,
      'departureAirportName': flight.departure.airportName,
      'departureCity': flight.departure.city,
      'departureCountry': flight.departure.country,
      'departureLatitude': flight.departure.latLon.latitude,
      'departureLongitude': flight.departure.latLon.longitude,

      // Arrival info
      'arrivalAirportCode': flight.arrival.code,
      'arrivalAirportName': flight.arrival.airportName,
      'arrivalCity': flight.arrival.city,
      'arrivalCountry': flight.arrival.country,
      'arrivalLatitude': flight.arrival.latLon.latitude,
      'arrivalLongitude': flight.arrival.latLon.longitude,

      // Waypoints
      'waypoints': flight.waypoints
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),

      // Corridor
      'corridor': flight.corridor
          .map(
            (point) => {
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(),

      // Maps (list)
      'maps': flight.maps.map((m) => m.toMap()).toList(),

      // Flight info
      'flightInfo': _flightInfoMapper.toMap(flight.flightInfo),

      // Metadata
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Convert Map from storage to Flight entity
  Flight _mapToFlight(Map<String, dynamic> map) {
    // Maps: prefer 'maps' list; fallback to legacy single 'flightMap'
    final List<FlightMap> mapsList = ((map['maps'] as List<dynamic>?) ?? [])
        .map((e) => FlightMap.fromMap(e as Map<String, dynamic>))
        .toList();
    if (mapsList.isEmpty && map['flightMap'] != null) {
      mapsList.add(FlightMap.fromMap(map['flightMap'] as Map<String, dynamic>));
    }

    // Flight info
    final FlightInfo info = (map['flightInfo'] is Map)
        ? _flightInfoMapper.fromMap((map['flightInfo'] as Map).cast<String, dynamic>())
        : FlightInfo.empty;

    return Flight(
      id: map['id'] as String,
      departure: Airport(
        code: map['departureAirportCode'] as String,
        name: map['departureAirportName'] as String,
        latLon: LatLng(
          map['departureLatitude'] as double,
          map['departureLongitude'] as double,
        ),
        city: map['departureCity'] as String,
        country: map['departureCountry'] as String? ?? 'Unknown',
      ),
      arrival: Airport(
        code: map['arrivalAirportCode'] as String,
        name: map['arrivalAirportName'] as String,
        latLon: LatLng(
          map['arrivalLatitude'] as double,
          map['arrivalLongitude'] as double,
        ),
        city: map['arrivalCity'] as String,
        country: map['arrivalCountry'] as String? ?? 'Unknown',
      ),
      waypoints: (map['waypoints'] as List<dynamic>? ?? [])
          .map(
            (point) => LatLng(
              point['latitude'] as double,
              point['longitude'] as double,
            ),
          )
          .toList(),
      corridor: (map['corridor'] as List<dynamic>? ?? [])
          .map(
            (point) => LatLng(
              point['latitude'] as double,
              point['longitude'] as double,
            ),
          )
          .toList(),
      maps: mapsList,
      flightInfo: info,
    );
  }

  /// Insert a new flight
  Future<String> insertFlight(Flight flight) async {
    final key = flight.id;
    _logger.log('Saving new flight info: ${flight.flightInfo}');
    final map = _flightToMap(flight);
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
    return _mapToFlight(map);
  }

  /// Get all flights
  Future<List<Flight>> getAllFlights() async {
    final records = await _database.flightsStore.find(_database.database);
    return records.map((record) => _mapToFlight(record.value)).toList();
  }

  /// Get recent flights
  Future<List<Flight>> getRecentFlights({int limit = 10}) async {
    final records = await _database.flightsStore.find(
      _database.database,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)], limit: limit),
    );
    return records.map((record) => _mapToFlight(record.value)).toList();
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
