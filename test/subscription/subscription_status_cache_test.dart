import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/subscription/subscription_status_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'persists the active RevenueCat product and base plan identifiers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final cache = SharedPrefsSubscriptionStatusCache();
      final status = SubscriptionStatus(
        isPro: true,
        entitlementId: 'Flymap Pro',
        productId: 'flymap_pro',
        productPlanId: 'monthly-base',
        expiresAt: DateTime.utc(2026, 9, 21),
        lastUpdatedAt: DateTime.utc(2026, 8, 21),
      );

      await cache.save(status);

      expect(await cache.load(), status);
    },
  );
}
