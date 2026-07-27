import 'package:flymap/domain/entity/flight_article.dart';
import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/flight_offline_content.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_route_insights.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/route_region.dart';

class FlightInfo extends Equatable {
  final FlightRouteInsights routeInsights;
  final FlightOfflineContent offlineContent;
  final FlightRouteMetrics routeMetrics;

  const FlightInfo(
    this.routeInsights,
    this.offlineContent, [
    this.routeMetrics = const FlightRouteMetrics(
      greatCircleDistanceKm: 0,
      cruiseMinutes: 0,
    ),
  ]);

  static const FlightInfo empty = FlightInfo(
    FlightRouteInsights.empty,
    FlightOfflineContent.empty,
    FlightRouteMetrics(greatCircleDistanceKm: 0, cruiseMinutes: 0),
  );

  String get overview => routeInsights.overview ?? '';
  List<RoutePoiSummary> get poi => routeInsights.poiHighlights;
  List<FlightArticle> get articles => offlineContent.articles;
  List<RouteRegion> get routeRegions => routeInsights.regions;
  int get routeCruiseMinutes => routeMetrics.cruiseMinutes;
  int get routeCruiseSpeedKmh =>
      routeMetrics.cruiseSpeedKmh?.round() ??
      FlightRouteMetrics.defaultCruiseSpeedKmh;

  bool get isEmpty =>
      routeInsights.isEmpty && offlineContent.isEmpty && routeMetrics.isEmpty;

  FlightInfo copyWith({
    FlightRouteInsights? routeInsights,
    FlightOfflineContent? offlineContent,
    FlightRouteMetrics? routeMetrics,
    String? overview,
    List<RoutePoiSummary>? poi,
    List<FlightArticle>? articles,
    List<RouteRegion>? routeRegions,
  }) {
    final nextRouteInsights =
        routeInsights ??
        this.routeInsights.copyWith(
          overview: overview,
          poiHighlights: poi,
          regions: routeRegions,
        );
    final nextOfflineContent =
        offlineContent ?? this.offlineContent.copyWith(articles: articles);
    return FlightInfo(
      nextRouteInsights,
      nextOfflineContent,
      routeMetrics ?? this.routeMetrics,
    );
  }

  @override
  List<Object?> get props => [routeInsights, offlineContent, routeMetrics];
}
