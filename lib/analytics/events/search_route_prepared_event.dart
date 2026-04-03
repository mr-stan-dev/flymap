import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/map_download_config.dart';

class SearchRoutePreparedEvent extends AnalyticsEvent {
  const SearchRoutePreparedEvent({
    required this.routeLengthKm,
    required this.routeLength,
    required this.mapDetail,
  });

  final double routeLengthKm;
  final RouteLength routeLength;
  final MapDetailLevel mapDetail;

  @override
  String get name => 'search_route_prepared';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'route_length_bucket': _routeBucket(routeLength),
    'map_detail': mapDetail.name,
  };
}

String _routeBucket(RouteLength routeLength) {
  return switch (routeLength) {
    RouteLength.short => 'short',
    RouteLength.mid => 'mid',
    RouteLength.long => 'long',
    RouteLength.superLong => 'super_long',
  };
}
