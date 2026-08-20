import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

enum RealRouteChoiceAction { shown, enterFlightNumber, keepRoute, dismissed }

/// Post-upgrade prompt offering to rebuild the flight from the real route.
class RealRouteChoiceEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const RealRouteChoiceEvent({
    required this.source,
    required this.action,
    this.creationAttemptId,
  });

  final PaywallSource source;
  final RealRouteChoiceAction action;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'real_route_choice';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'action': switch (action) {
      RealRouteChoiceAction.shown => 'shown',
      RealRouteChoiceAction.enterFlightNumber => 'enter_flight_number',
      RealRouteChoiceAction.keepRoute => 'keep_route',
      RealRouteChoiceAction.dismissed => 'dismissed',
    },
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
