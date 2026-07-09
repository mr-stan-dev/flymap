import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/subscription/paywall_source.dart';

class FlightUnlockSheetOpenedEvent extends FirebaseAnalyticsEvent {
  const FlightUnlockSheetOpenedEvent({
    required this.source,
    required this.unusedUnlockCount,
    required this.hasCachedProduct,
  });

  final PaywallSource source;
  final int unusedUnlockCount;
  final bool hasCachedProduct;

  @override
  String get firebaseEventName => 'flight_unlock_sheet_opened';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source.analyticsValue,
    'unused_unlock_count': unusedUnlockCount,
    'has_cached_product': hasCachedProduct ? 1 : 0,
  };
}
