import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

enum FlightUnlockActionType { useExisting, buyUnlock, viewProPlans }

class FlightUnlockActionEvent extends FirebaseAnalyticsEvent {
  const FlightUnlockActionEvent({
    required this.source,
    required this.action,
    required this.unusedUnlockCount,
  });

  final PaywallSource source;
  final FlightUnlockActionType action;
  final int unusedUnlockCount;

  @override
  String get firebaseEventName => 'flight_unlock_action';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'action': switch (action) {
      FlightUnlockActionType.useExisting => 'use_existing',
      FlightUnlockActionType.buyUnlock => 'buy_unlock',
      FlightUnlockActionType.viewProPlans => 'view_pro_plans',
    },
    'unused_unlock_count': unusedUnlockCount,
  };
}
