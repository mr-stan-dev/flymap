import 'package:equatable/equatable.dart';
import 'package:flymap/ui/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'airport.dart';
import 'map/flight_map.dart';

class Flight extends Equatable {
  final String id;
  final Airport departure;
  final Airport arrival;
  final List<LatLng> waypoints;
  final List<LatLng> corridor;
  final List<FlightMap> maps;

  const Flight({
    required this.id,
    required this.departure,
    required this.arrival,
    this.waypoints = const [],
    this.corridor = const [],
    this.maps = const [],
  });

  FlightMap? get flightMap => maps.isNotEmpty ? maps[0] : null;

  String get route =>
      '${departure.city}, ${departure.countryCode} - ${arrival.city}, ${arrival.countryCode}';

  double get distanceInKm {
    return MapUtils.distance(departure: departure, arrival: arrival);
  }

  @override
  List<Object?> get props => [
    id,
    departure,
    arrival,
    waypoints,
    corridor,
    maps,
  ];
}
