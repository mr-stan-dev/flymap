import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi.dart';
import 'package:latlong2/latlong.dart';

class RoutePoiSummary extends Equatable {
  const RoutePoiSummary({
    required this.poi,
    this.description = '',
    this.descriptionHtml = '',
    this.wiki = '',
    this.routeProgress,
  });

  final RoutePoi poi;
  final String description;
  final String descriptionHtml;
  final String wiki;
  final double? routeProgress;

  // Delegation getters for convenient field access.
  String get qid => poi.qid;
  String get name => poi.name;
  LatLng get latLon => poi.latLon;
  FlightPoiType get type => poi.type;
  int get sitelinks => poi.sitelinks;

  factory RoutePoiSummary.fromRoutePoi(
    RoutePoi poi, {
    required double routeProgress,
  }) {
    return RoutePoiSummary(poi: poi, routeProgress: routeProgress);
  }

  RoutePoiSummary copyWith({
    RoutePoi? poi,
    String? description,
    String? descriptionHtml,
    String? wiki,
    double? routeProgress,
  }) {
    return RoutePoiSummary(
      poi: poi ?? this.poi,
      description: description ?? this.description,
      descriptionHtml: descriptionHtml ?? this.descriptionHtml,
      wiki: wiki ?? this.wiki,
      routeProgress: routeProgress ?? this.routeProgress,
    );
  }

  @override
  List<Object?> get props => [
    poi,
    description,
    descriptionHtml,
    wiki,
    routeProgress,
  ];
}
