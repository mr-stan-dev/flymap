import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';

import 'flight_poi_db_mapper.dart';
import 'mapper_utils.dart';

class FlightInfoDBKeys {
  static const overview = 'overview';
  static const poi = 'poi';
}

class FlightInfoDbMapper {
  final FlightPoiDbMapper _poiMapper;

  FlightInfoDbMapper({FlightPoiDbMapper? poiMapper})
    : _poiMapper = poiMapper ?? FlightPoiDbMapper();

  FlightInfo toFlightInfo(Map<String, dynamic> map) {
    final list = map.getListOfMaps(FlightInfoDBKeys.poi);
    final List<FlightPoi> pois = list
        .map(_poiMapper.fromDb)
        .whereType<FlightPoi>()
        .toList();
    final overview = map.getString(FlightInfoDBKeys.overview);
    return FlightInfo(overview, pois);
  }

  Map<String, dynamic> toFlightInfoMap(FlightInfo info) => <String, dynamic>{
    FlightInfoDBKeys.overview: info.overview,
    FlightInfoDBKeys.poi: info.poi.map(_poiMapper.toDb).toList(),
  };
}
