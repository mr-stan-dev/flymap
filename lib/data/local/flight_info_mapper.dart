import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';

class FlightInfoMapper {
  FlightInfo fromMap(Map<String, dynamic> map) {
    final dynamic list = map['poi'];
    final pois = (list is List)
        ? list
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(FlightPoi.fromMap)
        .toList()
        : <FlightPoi>[];
    final overview = (map['overview'] ?? '')
        .toString();
    return FlightInfo(overview, pois);
  }

  Map<String, dynamic> toMap(FlightInfo info) => <String, dynamic>{
    'overview': info.overview,
    'poi': info.poi
        .map(
          (p) => <String, dynamic>{
        'coordinates':
        '${p.coordinates.latitude},${p.coordinates.longitude}',
        'type': p.type,
        'name': p.name,
        'description': p.description,
        'fly_view': p.flyView,
        'wiki': p.wiki,
      },
    )
        .toList(),
  };
}