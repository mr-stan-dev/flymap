import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class FlightPoi extends Equatable {
  final LatLng coordinates;
  final String type;
  final String description;

  const FlightPoi({
    required this.coordinates,
    required this.type,
    required this.description,
  });

  factory FlightPoi.fromMap(Map<String, dynamic> map) {
    final dynamic coordValue = map['poi_coordinates'];
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
      type: (map['poi_type'] ?? '').toString(),
      description: (map['poi_description'] ?? '').toString(),
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
  ];
}
