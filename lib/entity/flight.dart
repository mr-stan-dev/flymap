import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'airport.dart';
import 'flight_info.dart';
import 'flight_map.dart';
import 'flight_route.dart';

class Flight extends Equatable {
  final String id;
  final FlightRoute route;
  final List<FlightMap> maps;
  final FlightInfo info;
  final DateTime createdAt;

  const Flight({
    required this.id,
    required this.route,
    this.maps = const [],
    required this.info,
    required this.createdAt,
  });

  FlightMap? get flightMap => maps.isNotEmpty ? maps[0] : null;

  // Convenience getters to reduce refactor blast radius
  Airport get departure => route.departure;

  Airport get arrival => route.arrival;

  List<LatLng> get waypoints => route.waypoints;

  List<LatLng> get corridor => route.corridor;

  String get routeName => '${departure.nameShort} -> ${arrival.nameShort}';

  @override
  List<Object?> get props => [id, route, maps, info, createdAt];
}
