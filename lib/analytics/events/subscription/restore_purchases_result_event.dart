import 'package:flymap/analytics/events/analytics_event.dart';

enum RestorePurchasesAnalyticsResult {
  proRestored('pro_restored'),
  noSubscription('no_subscription'),
  error('error');

  const RestorePurchasesAnalyticsResult(this.analyticsValue);

  final String analyticsValue;
}

class RestorePurchasesResultEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const RestorePurchasesResultEvent({required this.result});

  final RestorePurchasesAnalyticsResult result;

  @override
  String get firebaseEventName => 'restore_purchases_result';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'result': result.analyticsValue,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
