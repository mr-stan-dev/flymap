import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';

class FlightUnlockPurchaseResultEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const FlightUnlockPurchaseResultEvent({
    required this.source,
    required this.result,
    required this.productId,
    required this.balanceAfter,
  });

  final PaywallSource source;
  final FlightUnlockPurchaseStatus result;
  final String productId;
  final int balanceAfter;

  @override
  String get firebaseEventName => 'flight_unlock_purchase_result';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'result': result.name,
    'product_id': productId,
    'balance_after': balanceAfter,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
