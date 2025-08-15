import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:flymap/entity/airport.dart';

class FlightPreview extends Equatable {
  final Airport departure;
  final Airport arrival;
  final List<LatLng> waypoints;
  final List<LatLng> corridor;

  const FlightPreview({
    required this.departure,
    required this.arrival,
    required this.waypoints,
    required this.corridor,
  });

  @override
  List<Object?> get props => [departure, arrival, waypoints, corridor];
}
