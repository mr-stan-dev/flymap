import 'package:flymap/analytics/events/analytics_event.dart';

enum SelectedRouteType {
  airports('airports'),
  flightNumber('flight_number'),
  realRoute('real_route');

  const SelectedRouteType(this.analyticsValue);

  final String analyticsValue;
}

class RouteTypeSelectedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const RouteTypeSelectedEvent({
    required this.routeType,
    required this.isProUser,
    required this.hasPendingFlightUnlock,
    this.entrySource,
    this.creationAttemptId,
  });

  final SelectedRouteType routeType;
  final bool isProUser;
  final bool hasPendingFlightUnlock;
  final String? entrySource;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'route_type_selected';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_type': routeType.analyticsValue,
    'is_pro_user': isProUser,
    'has_pending_flight_unlock': hasPendingFlightUnlock,
    if (entrySource case final source?) 'entry_source': source,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    if (entrySource != null || creationAttemptId != null) 'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
