import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';

class PaywallResultEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const PaywallResultEvent({
    required this.source,
    required this.result,
    this.creationAttemptId,
  });

  final PaywallSource source;
  final SubscriptionPaywallResult result;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'paywall_result';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'result': result.name,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
