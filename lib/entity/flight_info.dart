import 'package:flymap/entity/flight_article.dart';
import 'package:equatable/equatable.dart';
import 'package:flymap/entity/route_poi_summary.dart';

class FlightInfo extends Equatable {
  final String overview;
  final List<RoutePoiSummary> poi;
  final List<FlightArticle> articles;

  const FlightInfo(this.overview, this.poi, [this.articles = const []]);

  static const FlightInfo empty = FlightInfo(
    '',
    <RoutePoiSummary>[],
    <FlightArticle>[],
  );
  bool get isEmpty => overview.isEmpty && poi.isEmpty && articles.isEmpty;

  FlightInfo copyWith({
    String? overview,
    List<RoutePoiSummary>? poi,
    List<FlightArticle>? articles,
  }) {
    return FlightInfo(
      overview ?? this.overview,
      poi ?? this.poi,
      articles ?? this.articles,
    );
  }

  @override
  List<Object?> get props => [overview, poi, articles];
}
