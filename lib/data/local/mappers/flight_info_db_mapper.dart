import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/entity/flight_article.dart';

import 'flight_article_db_mapper.dart';
import 'route_poi_summary_db_mapper.dart';
import 'mapper_utils.dart';

class FlightInfoDBKeys {
  static const overview = 'overview';
  static const poi = 'poi';
  static const articles = 'articles';
}

class FlightInfoDbMapper {
  final RoutePoiSummaryDbMapper _poiMapper;
  final FlightArticleDbMapper _articleMapper;

  FlightInfoDbMapper({
    RoutePoiSummaryDbMapper? poiMapper,
    FlightArticleDbMapper? articleMapper,
  }) : _poiMapper = poiMapper ?? RoutePoiSummaryDbMapper(),
       _articleMapper = articleMapper ?? FlightArticleDbMapper();

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
    final overview = map.getString(FlightInfoDBKeys.overview);
    return FlightInfo(overview, pois, articles);
  }

  Map<String, dynamic> toFlightInfoMap(FlightInfo info) => <String, dynamic>{
    FlightInfoDBKeys.overview: info.overview,
    FlightInfoDBKeys.poi: info.poi.map(_poiMapper.toDb).toList(),
    FlightInfoDBKeys.articles: info.articles.map(_articleMapper.toDb).toList(),
  };
}
