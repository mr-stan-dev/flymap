import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

enum RealRouteChoiceAction { shown, enterFlightNumber, keepRoute }

/// Post-upgrade prompt offering to rebuild the flight from the real route.
class RealRouteChoiceEvent extends FirebaseAnalyticsEvent {
  const RealRouteChoiceEvent({required this.source, required this.action});

  final PaywallSource source;
  final RealRouteChoiceAction action;

  @override
  String get firebaseEventName => 'real_route_choice';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'action': switch (action) {
      RealRouteChoiceAction.shown => 'shown',
      RealRouteChoiceAction.enterFlightNumber => 'enter_flight_number',
      RealRouteChoiceAction.keepRoute => 'keep_route',
    },
  };
}
