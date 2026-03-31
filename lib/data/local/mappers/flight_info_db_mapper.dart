import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_poi.dart';
import 'package:flymap/entity/flight_article.dart';

import 'flight_article_db_mapper.dart';
import 'flight_poi_db_mapper.dart';
import 'mapper_utils.dart';

class FlightInfoDBKeys {
  static const overview = 'overview';
  static const poi = 'poi';
  static const articles = 'articles';
}

class FlightInfoDbMapper {
  final FlightPoiDbMapper _poiMapper;
  final FlightArticleDbMapper _articleMapper;

  FlightInfoDbMapper({
    FlightPoiDbMapper? poiMapper,
    FlightArticleDbMapper? articleMapper,
  }) : _poiMapper = poiMapper ?? FlightPoiDbMapper(),
       _articleMapper = articleMapper ?? FlightArticleDbMapper();

  FlightInfo toFlightInfo(Map<String, dynamic> map) {
    final poiList = map.getListOfMaps(FlightInfoDBKeys.poi);
    final List<FlightPoi> pois = poiList
        .map(_poiMapper.fromDb)
        .whereType<FlightPoi>()
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
