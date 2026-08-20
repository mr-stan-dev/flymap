import 'package:flymap/analytics/events/analytics_event.dart';

enum RouteTypeCardType {
  basic('basic'),
  realRoute('real_route');

  const RouteTypeCardType(this.analyticsValue);

  final String analyticsValue;
}

enum RouteTypeAccessState {
  free('free'),
  pro('pro'),
  singleFlightUnlock('single_flight_unlock');

  const RouteTypeAccessState(this.analyticsValue);

  final String analyticsValue;
}

class RouteTypeCardTappedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const RouteTypeCardTappedEvent({
    required this.routeType,
    required this.accessState,
    required this.entrySource,
    required this.creationAttemptId,
  });

  final RouteTypeCardType routeType;
  final RouteTypeAccessState accessState;
  final String entrySource;
  final String creationAttemptId;

  @override
  String get firebaseEventName => 'route_type_card_tapped';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_type': routeType.analyticsValue,
    'access_state': accessState.analyticsValue,
    'entry_source': entrySource,
    'creation_attempt_id': creationAttemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
