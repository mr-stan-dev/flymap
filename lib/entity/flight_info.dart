import 'package:flymap/entity/flight_article.dart';
import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight_poi.dart';

class FlightInfo extends Equatable {
  final String overview;
  final List<FlightPoi> poi;
  final List<FlightArticle> articles;

  const FlightInfo(this.overview, this.poi, [this.articles = const []]);

  static const FlightInfo empty = FlightInfo(
    '',
    <FlightPoi>[],
    <FlightArticle>[],
  );
  bool get isEmpty => overview.isEmpty && poi.isEmpty && articles.isEmpty;

  FlightInfo copyWith({
    String? overview,
    List<FlightPoi>? poi,
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
