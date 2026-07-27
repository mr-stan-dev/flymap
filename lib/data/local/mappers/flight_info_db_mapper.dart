import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_offline_content.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_insights.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/route_region.dart';

import 'flight_article_db_mapper.dart';
import 'route_poi_summary_db_mapper.dart';
import 'mapper_utils.dart';
import 'route_region_db_mapper.dart';

class FlightInfoDBKeys {
  static const overview = 'overview';
  static const poi = 'poi';
  static const articles = 'articles';
  static const routeRegions = 'routeRegions';
  static const routeTotalMinutes = 'routeTotalMinutes';
  static const routeCruiseSpeedKmh = 'routeCruiseSpeedKmh';
}

class FlightInfoDbMapper {
  final RoutePoiSummaryDbMapper _poiMapper;
  final FlightArticleDbMapper _articleMapper;
  final RouteRegionDbMapper _routeRegionMapper;

  FlightInfoDbMapper({
    RoutePoiSummaryDbMapper? poiMapper,
    FlightArticleDbMapper? articleMapper,
    RouteRegionDbMapper? routeRegionMapper,
  }) : _poiMapper = poiMapper ?? RoutePoiSummaryDbMapper(),
       _articleMapper = articleMapper ?? FlightArticleDbMapper(),
       _routeRegionMapper = routeRegionMapper ?? RouteRegionDbMapper();

  FlightInfo toFlightInfo(Map<String, dynamic> map) {
    final poiList = map.getListOfMaps(FlightInfoDBKeys.poi);
    final List<RoutePoiSummary> pois = poiList
        .map(_poiMapper.fromDb)
        .whereType<RoutePoiSummary>()
        .toList();
    final articleList = map.getListOfMaps(FlightInfoDBKeys.articles);
    final List<FlightArticle> articles = articleList
        .map(_articleMapper.fromDb)
        .whereType<FlightArticle>()
        .toList();
    final regionList = map.getListOfMaps(FlightInfoDBKeys.routeRegions);
    final List<RouteRegion> routeRegions = regionList
        .map(_routeRegionMapper.fromDb)
        .whereType<RouteRegion>()
        .toList();
    final overview = map.getString(FlightInfoDBKeys.overview);
    // The legacy 'routeTotalMinutes' key holds cruise-only minutes.
    final cruiseMinutesRaw = map[FlightInfoDBKeys.routeTotalMinutes];
    final cruiseMinutes = cruiseMinutesRaw == null
        ? null
        : map.getInt(FlightInfoDBKeys.routeTotalMinutes);
    final routeCruiseSpeedKmh = map.getInt(
      FlightInfoDBKeys.routeCruiseSpeedKmh,
    );
    final inferredDistanceKm = cruiseMinutes != null && routeCruiseSpeedKmh > 0
        ? routeCruiseSpeedKmh * (cruiseMinutes / 60.0)
        : 0.0;
    return FlightInfo(
      FlightRouteInsights(
        overview: overview.isEmpty ? null : overview,
        poiHighlights: pois,
        regions: routeRegions,
      ),
      FlightOfflineContent(articles: articles),
      FlightRouteMetrics(
        greatCircleDistanceKm: inferredDistanceKm,
        cruiseMinutes: cruiseMinutes ?? 0,
      ),
    );
  }

  Map<String, dynamic> toFlightInfoMap(FlightInfo info) => <String, dynamic>{
    FlightInfoDBKeys.overview: info.overview,
    FlightInfoDBKeys.poi: info.poi.map(_poiMapper.toDb).toList(),
    FlightInfoDBKeys.articles: info.articles.map(_articleMapper.toDb).toList(),
    FlightInfoDBKeys.routeRegions: info.routeRegions
        .map(_routeRegionMapper.toDb)
        .toList(),
    if (info.routeCruiseMinutes > 0)
      FlightInfoDBKeys.routeTotalMinutes: info.routeCruiseMinutes,
    FlightInfoDBKeys.routeCruiseSpeedKmh: info.routeCruiseSpeedKmh,
  };
}
