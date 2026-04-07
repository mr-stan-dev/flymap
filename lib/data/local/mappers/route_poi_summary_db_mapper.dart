import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:latlong2/latlong.dart';

import 'mapper_utils.dart';

class RoutePoiSummaryDbKeys {
  static const latitude = 'latitude';
  static const longitude = 'longitude';
  static const type = 'type';
  static const name = 'name';
  static const description = 'description';
  static const descriptionHtml = 'description_html';
  static const wiki = 'wiki';
  static const qid = 'qid';
  static const sitelinks = 'sitelinks';
  static const routeProgress = 'route_progress';
}

class RoutePoiSummaryDbMapper {
  RoutePoiSummary? fromDb(Map<String, dynamic> map) {
    final latNum = map.getDouble(RoutePoiSummaryDbKeys.latitude);
    final lonNum = map.getDouble(RoutePoiSummaryDbKeys.longitude);
    return RoutePoiSummary(
      poi: RoutePoi(
        qid: map.getString(RoutePoiSummaryDbKeys.qid),
        name: map.getString(RoutePoiSummaryDbKeys.name),
        latLon: LatLng(latNum.toDouble(), lonNum.toDouble()),
        type: FlightPoiType.fromRaw(map.getString(RoutePoiSummaryDbKeys.type)),
        sitelinks: map.getInt(RoutePoiSummaryDbKeys.sitelinks),
      ),
      description: map.getString(RoutePoiSummaryDbKeys.description),
      descriptionHtml: map.getString(RoutePoiSummaryDbKeys.descriptionHtml),
      wiki: map.getString(RoutePoiSummaryDbKeys.wiki),
      routeProgress: map
          .getNum(RoutePoiSummaryDbKeys.routeProgress)
          ?.toDouble(),
    );
  }

  Map<String, dynamic> toDb(RoutePoiSummary summary) => <String, dynamic>{
    RoutePoiSummaryDbKeys.latitude: summary.poi.latLon.latitude,
    RoutePoiSummaryDbKeys.longitude: summary.poi.latLon.longitude,
    RoutePoiSummaryDbKeys.type: summary.poi.type.rawValue,
    RoutePoiSummaryDbKeys.name: summary.poi.name,
    RoutePoiSummaryDbKeys.description: summary.description,
    RoutePoiSummaryDbKeys.descriptionHtml: summary.descriptionHtml,
    RoutePoiSummaryDbKeys.wiki: summary.wiki,
    RoutePoiSummaryDbKeys.qid: summary.poi.qid,
    RoutePoiSummaryDbKeys.sitelinks: summary.poi.sitelinks,
    RoutePoiSummaryDbKeys.routeProgress: summary.routeProgress,
  };
}
