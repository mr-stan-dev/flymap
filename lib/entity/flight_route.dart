import 'package:equatable/equatable.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:latlong2/latlong.dart';
import 'package:flymap/entity/airport.dart';

class FlightRoute extends Equatable {
  final Airport departure;
  final Airport arrival;
  final List<LatLng> waypoints;
  final List<LatLng> corridor;

  const FlightRoute({
    required this.departure,
    required this.arrival,
    required this.waypoints,
    required this.corridor,
  });

  double get distanceInKm {
    return MapUtils.distance(departure: departure, arrival: arrival);
  }

  @override
  List<Object?> get props => [departure, arrival, waypoints, corridor];
}
