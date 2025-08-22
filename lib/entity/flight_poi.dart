import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class FlightPoi extends Equatable {
  final LatLng coordinates;
  final String type;
  final String description;
  final String name;
  final String flyView;
  final String wiki;

  const FlightPoi({
    required this.coordinates,
    required this.type,
    required this.description,
    required this.name,
    required this.flyView,
    required this.wiki,
  });

  @override
  List<Object?> get props => [
    coordinates.latitude,
    coordinates.longitude,
    type,
    description,
    name,
    flyView,
    wiki,
  ];
}
