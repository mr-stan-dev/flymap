import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

enum FlightUnlockActionType { useExisting, buyUnlock, viewProPlans, dismissed }

class FlightUnlockActionEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const FlightUnlockActionEvent({
    required this.source,
    required this.action,
    required this.unusedUnlockCount,
    required this.gateAttemptId,
    this.creationAttemptId,
  });

  final PaywallSource source;
  final FlightUnlockActionType action;
  final int unusedUnlockCount;
  final String gateAttemptId;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'flight_unlock_action';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'action': switch (action) {
      FlightUnlockActionType.useExisting => 'use_existing',
      FlightUnlockActionType.buyUnlock => 'buy_unlock',
      FlightUnlockActionType.viewProPlans => 'view_pro_plans',
      FlightUnlockActionType.dismissed => 'dismissed',
    },
    'unused_unlock_count': unusedUnlockCount,
    'gate_attempt_id': gateAttemptId,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
