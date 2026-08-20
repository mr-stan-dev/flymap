import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/map_detail_level.dart';
import 'package:flymap/map_download_config.dart';

class SearchRoutePreparedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SearchRoutePreparedEvent({
    required this.routeLengthKm,
    required this.routeLength,
    required this.mapDetail,
    required this.routeSource,
    this.creationAttemptId,
  });

  final double routeLengthKm;
  final RouteLength routeLength;
  final MapDetailLevel mapDetail;
  final FlightRouteSource routeSource;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'search_route_prepared';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'route_length_bucket': _routeBucket(routeLength),
    'map_detail': mapDetail.name,
    'route_source': routeSource.rawValue,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    if (creationAttemptId != null) 'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}

String _routeBucket(RouteLength routeLength) {
  return switch (routeLength) {
    RouteLength.short => 'short',
    RouteLength.mid => 'mid',
    RouteLength.long => 'long',
    RouteLength.superLong => 'super_long',
  };
}
