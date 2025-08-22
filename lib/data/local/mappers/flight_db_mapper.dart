import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_map.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:latlong2/latlong.dart';

import 'airport_db_mapper.dart';
import 'flight_info_db_mapper.dart';

class FlightDbMapper {
  final AirportDbMapper _airportMapper;
  final FlightInfoDbMapper _infoMapper;

  FlightDbMapper({
    AirportDbMapper? airportMapper,
    FlightInfoDbMapper? infoMapper,
  }) : _airportMapper = airportMapper ?? AirportDbMapper(),
       _infoMapper = infoMapper ?? FlightInfoDbMapper();

  Map<String, dynamic> toDb(Flight flight) {
    final out = <String, dynamic>{
      'id': flight.id,
      'maps': flight.maps.map((m) => m.toMap()).toList(),
      'flightInfo': _infoMapper.toFlightInfoMap(flight.info),
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    out['departure'] = _airportMapper.toDb(flight.route.departure);
    out['arrival'] = _airportMapper.toDb(flight.route.arrival);

    out['waypoints'] = flight.route.waypoints
        .map(
          (p) => <String, dynamic>{
            'latitude': p.latitude,
            'longitude': p.longitude,
          },
        )
        .toList();
    out['corridor'] = flight.route.corridor
        .map(
          (p) => <String, dynamic>{
            'latitude': p.latitude,
            'longitude': p.longitude,
          },
        )
        .toList();

    return out;
  }

  Flight fromDb(Map<String, dynamic> map) {
    final mapsList = ((map['maps'] as List<dynamic>?) ?? [])
        .map((e) => FlightMap.fromMap(e as Map<String, dynamic>))
        .toList();
    if (mapsList.isEmpty && map['flightMap'] != null) {
      mapsList.add(FlightMap.fromMap(map['flightMap'] as Map<String, dynamic>));
    }

    final route = FlightRoute(
      departure: _airportMapper.fromDb(
        (map['departure'] as Map).cast<String, dynamic>(),
      ),
      arrival: _airportMapper.fromDb(
        (map['arrival'] as Map).cast<String, dynamic>(),
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
    );

    final info = (map['flightInfo'] is Map)
        ? _infoMapper.toFlightInfo(
            (map['flightInfo'] as Map).cast<String, dynamic>(),
          )
        : null;

    return Flight(
      id: (map['id'] ?? '').toString(),
      route: route,
      maps: mapsList,
      info: info ?? _infoMapper.toFlightInfo({}),
    );
  }
}
