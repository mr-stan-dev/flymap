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

  factory FlightPoi.fromMap(Map<String, dynamic> map) {
    // coordinates can be provided as 'coordinates' (new) or 'poi_coordinates' (legacy)
    final dynamic coordValue = map['coordinates'] ?? map['poi_coordinates'];
    LatLng coords;
    if (coordValue is String) {
      final parts = coordValue.split(',');
      final double? lat = parts.isNotEmpty
          ? double.tryParse(parts[0].trim())
          : null;
      final double? lon = parts.length > 1
          ? double.tryParse(parts[1].trim())
          : null;
      coords = LatLng(lat ?? 0.0, lon ?? 0.0);
    } else if (coordValue is List && coordValue.length >= 2) {
      final double? lat = _toDouble(coordValue[0]);
      final double? lon = _toDouble(coordValue[1]);
      coords = LatLng(lat ?? 0.0, lon ?? 0.0);
    } else {
      coords = const LatLng(0.0, 0.0);
    }

    return FlightPoi(
      coordinates: coords,
      type: (map['type'] ?? map['poi_type'] ?? '').toString(),
      description: (map['description'] ?? map['poi_description'] ?? '')
          .toString(),
      name: (map['name'] ?? map['poi_name'] ?? '').toString(),
      flyView: (map['fly_view'] ?? '').toString(),
      wiki: (map['wiki'] ?? '').toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

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
