import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:latlong2/latlong.dart';

import 'airport_db_mapper.dart';
import 'flight_info_db_mapper.dart';
import 'flight_map_mapper.dart';

class FlightDBKeys {
  static const flightMaps = 'maps';
  static const id = 'id';
  static const flightInfo = 'flightInfo';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const departure = 'departure';
  static const arrival = 'arrival';
  static const waypoints = 'waypoints';
  static const corridor = 'corridor';
  static const latitude = 'latitude';
  static const longitude = 'longitude';
}

class FlightDbMapper {
  final AirportDbMapper _airportMapper;
  final FlightInfoDbMapper _infoMapper;
  final FlightMapDbMapper _mapMapper = FlightMapDbMapper();

  FlightDbMapper({
    AirportDbMapper? airportMapper,
    FlightInfoDbMapper? infoMapper,
  }) : _airportMapper = airportMapper ?? AirportDbMapper(),
       _infoMapper = infoMapper ?? FlightInfoDbMapper();

  Map<String, dynamic> toDb(Flight flight) {
    final nowIso = DateTime.now().toIso8601String();
    final out = <String, dynamic>{
      FlightDBKeys.id: flight.id,
      FlightDBKeys.flightMaps: flight.maps
          .map((m) => _mapMapper.toDb(m))
          .toList(),
      FlightDBKeys.flightInfo: _infoMapper.toFlightInfoMap(flight.info),
      FlightDBKeys.createdAt: flight.createdAt.toIso8601String(),
      FlightDBKeys.updatedAt: nowIso,
    };

    out[FlightDBKeys.departure] = _airportMapper.toDb(flight.route.departure);
    out[FlightDBKeys.arrival] = _airportMapper.toDb(flight.route.arrival);

    out[FlightDBKeys.waypoints] = flight.route.waypoints
        .map(
          (p) => <String, dynamic>{
            FlightDBKeys.latitude: p.latitude,
            FlightDBKeys.longitude: p.longitude,
          },
        )
        .toList();
    out[FlightDBKeys.corridor] = flight.route.corridor
        .map(
          (p) => <String, dynamic>{
            FlightDBKeys.latitude: p.latitude,
            FlightDBKeys.longitude: p.longitude,
          },
        )
        .toList();

    return out;
  }

  Flight fromDb(Map<String, dynamic> map) {
    final mapsList = ((map[FlightDBKeys.flightMaps] as List<dynamic>?) ?? [])
        .map((e) => _mapMapper.fromDb(e as Map<String, dynamic>))
        .toList();

    final route = FlightRoute(
      departure: _airportMapper.fromDb(
        (map[FlightDBKeys.departure] as Map).cast<String, dynamic>(),
      ),
      arrival: _airportMapper.fromDb(
        (map[FlightDBKeys.arrival] as Map<String, dynamic>),
      ),
      waypoints: (map[FlightDBKeys.waypoints] as List<dynamic>? ?? [])
          .map(
            (point) => LatLng(
              point[FlightDBKeys.latitude] as double,
              point[FlightDBKeys.longitude] as double,
            ),
          )
          .toList(),
      corridor: (map[FlightDBKeys.corridor] as List<dynamic>? ?? [])
          .map(
            (point) => LatLng(
              point[FlightDBKeys.latitude] as double,
              point[FlightDBKeys.longitude] as double,
            ),
          )
          .toList(),
    );

    final info = _infoMapper.toFlightInfo(
      (map[FlightDBKeys.flightInfo] as Map<String, dynamic>),
    );

    final createdAtStr = (map[FlightDBKeys.createdAt] ?? '').toString();
    final createdAt = createdAtStr.isNotEmpty
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();

    return Flight(
      id: (map[FlightDBKeys.id] ?? '').toString(),
      route: route,
      maps: mapsList,
      info: info,
      createdAt: createdAt,
    );
  }
}
