import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';

class PaywallResultEvent extends AnalyticsEvent {
  const PaywallResultEvent({required this.source, required this.result});

  final PaywallSource source;
  final SubscriptionPaywallResult result;

  @override
  String get name => 'paywall_result';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'source': source.analyticsValue,
    'result': result.name,
  };
}
