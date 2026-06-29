import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/map_download_config.dart';

enum FlightOpenedAccessTier {
  free('free'),
  pro('pro'),
  flightUnlock('flight_unlock');

  const FlightOpenedAccessTier(this.analyticsValue);

  final String analyticsValue;
}

class FlightOpenedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const FlightOpenedEvent({
    required this.routeSource,
    required this.routeLength,
    required this.accessTier,
  });

  final FlightRouteSource routeSource;
  final RouteLength routeLength;
  final FlightOpenedAccessTier accessTier;

  @override
  String get firebaseEventName => 'flight_opened';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_source': routeSource.rawValue,
    'route_length_bucket': _routeBucket(routeLength),
    'access_tier': accessTier.analyticsValue,
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
