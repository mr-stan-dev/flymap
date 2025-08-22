import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';

import 'flight_poi_db_mapper.dart';

class FlightInfoDbMapper {
  final FlightPoiDbMapper _poiMapper;

  FlightInfoDbMapper({FlightPoiDbMapper? poiMapper})
    : _poiMapper = poiMapper ?? FlightPoiDbMapper();

  FlightInfo toFlightInfo(Map<String, dynamic> map) {
    final dynamic list = map['poi'];
    final List<FlightPoi> pois = (list is List)
        ? list
              .whereType<Map>()
              .map((e) => e.cast<String, dynamic>())
              .map(_poiMapper.fromDb)
              .whereType<FlightPoi>()
              .toList()
        : <FlightPoi>[];
    final overview = (map['overview'] ?? '').toString();
    return FlightInfo(overview, pois);
  }

  Map<String, dynamic> toFlightInfoMap(FlightInfo info) => <String, dynamic>{
    'overview': info.overview,
    'poi': info.poi.map(_poiMapper.toDb).toList(),
  };
}
