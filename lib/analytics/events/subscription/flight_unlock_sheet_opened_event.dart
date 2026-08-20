import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

class FlightUnlockSheetOpenedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const FlightUnlockSheetOpenedEvent({
    required this.source,
    required this.unusedUnlockCount,
    required this.hasCachedProduct,
    required this.gateAttemptId,
    this.creationAttemptId,
  });

  final PaywallSource source;
  final int unusedUnlockCount;
  final bool hasCachedProduct;
  final String gateAttemptId;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'flight_unlock_sheet_opened';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'unused_unlock_count': unusedUnlockCount,
    'has_cached_product': hasCachedProduct ? 1 : 0,
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
