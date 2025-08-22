import 'package:flymap/entity/flight_poi.dart';
import 'package:latlong2/latlong.dart';

class FlightPoiDbMapper {
  FlightPoi? fromDb(Map<String, dynamic> map) {
    final dynamic coordinates = map['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      final double? lat = _toDouble(coordinates[0]);
      final double? lon = _toDouble(coordinates[1]);
      if (lat != null && lon != null) {
        return FlightPoi(
          coordinates: LatLng(lat, lon),
          type: (map['type'] ?? '').toString(),
          description: (map['description'] ?? '').toString(),
          name: (map['name'] ?? '').toString(),
          flyView: (map['fly_view'] ?? '').toString(),
          wiki: (map['wiki'] ?? '').toString(),
        );
      }
    }
    return null;
  }

  Map<String, dynamic> toDb(FlightPoi poi) => <String, dynamic>{
    'coordinates': '${poi.coordinates.latitude},${poi.coordinates.longitude}',
    'type': poi.type,
    'name': poi.name,
    'description': poi.description,
    'fly_view': poi.flyView,
    'wiki': poi.wiki,
  };

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
