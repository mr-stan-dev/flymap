import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/map_download_config.dart';

class SearchRouteNotSupportedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SearchRouteNotSupportedEvent({
    required this.reason,
    required this.routeLengthKm,
    this.routeSource,
    this.routeLength,
    this.recommendedNextAction,
    this.creationAttemptId,
  });

  final String reason;
  final double routeLengthKm;
  final FlightRouteSource? routeSource;
  final RouteLength? routeLength;
  final String? recommendedNextAction;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'search_route_not_supported';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'reason': reason,
    'route_length_km': routeLengthKm.round(),
    if (routeSource case final source?) 'route_source': source.rawValue,
    if (routeLength case final length?)
      'route_length_bucket': _routeBucket(length),
    if (recommendedNextAction case final action?)
      'recommended_next_action': action,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    if (routeSource != null ||
        routeLength != null ||
        recommendedNextAction != null ||
        creationAttemptId != null)
      'tracking_version': 2,
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
