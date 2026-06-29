import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

class PaywallPresentedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const PaywallPresentedEvent({
    required this.source,
    required this.isProUser,
    required this.hasProducts,
  });

  final PaywallSource source;
  final bool isProUser;
  final bool hasProducts;

  @override
  String get firebaseEventName => 'paywall_presented';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'is_pro_user': isProUser,
    'has_products': hasProducts,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
