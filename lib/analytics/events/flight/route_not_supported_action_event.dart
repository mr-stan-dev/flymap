import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';

enum RouteNotSupportedAction {
  back('back'),
  dismiss('dismiss');

  const RouteNotSupportedAction(this.analyticsValue);

  final String analyticsValue;
}

class RouteNotSupportedActionEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const RouteNotSupportedActionEvent({
    required this.reason,
    required this.action,
    required this.routeSource,
    required this.creationAttemptId,
  });

  final String reason;
  final RouteNotSupportedAction action;
  final FlightRouteSource routeSource;
  final String creationAttemptId;

  @override
  String get firebaseEventName => 'route_not_supported_action';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'reason': reason,
    'action': action.analyticsValue,
    'route_source': routeSource.rawValue,
    'creation_attempt_id': creationAttemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
