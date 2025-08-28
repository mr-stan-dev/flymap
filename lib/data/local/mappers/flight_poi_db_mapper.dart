import 'package:flymap/entity/flight_poi.dart';
import 'package:latlong2/latlong.dart';

import 'mapper_utils.dart';

class FlightPoiDBKeys {
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const type = 'type';
  static const name = 'name';
  static const description = 'description';
  static const flyView = 'fly_view';
  static const wiki = 'wiki';
}

class FlightPoiDbMapper {
  FlightPoi? fromDb(Map<String, dynamic> map) {
    final latNum = map.getDouble(FlightPoiDBKeys.latitude);
    final lonNum = map.getDouble(FlightPoiDBKeys.longitude);

    return FlightPoi(
      coordinates: LatLng(latNum.toDouble(), lonNum.toDouble()),
      type: map.getString(FlightPoiDBKeys.type),
      description: map.getString(FlightPoiDBKeys.description),
      name: map.getString(FlightPoiDBKeys.name),
      flyView: map.getString(FlightPoiDBKeys.flyView),
      wiki: map.getString(FlightPoiDBKeys.wiki),
    );
  }

  Map<String, dynamic> toDb(FlightPoi poi) => <String, dynamic>{
    FlightPoiDBKeys.latitude: poi.coordinates.latitude,
    FlightPoiDBKeys.longitude: poi.coordinates.longitude,
    FlightPoiDBKeys.type: poi.type,
    FlightPoiDBKeys.name: poi.name,
    FlightPoiDBKeys.description: poi.description,
    FlightPoiDBKeys.flyView: poi.flyView,
    FlightPoiDBKeys.wiki: poi.wiki,
  };
}
