import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';

void main() {
  group('RevenueCatEnvConfig', () {
    test('falls back to pro entitlement when empty', () {
      const config = RevenueCatEnvConfig(
        iosApiKey: 'ios_key',
        androidApiKey: 'android_key',
        entitlementPro: '  ',
      );

      expect(config.entitlementId, 'Flymap Pro');
    });

    test('returns platform-specific API key', () {
      const config = RevenueCatEnvConfig(
        iosApiKey: 'ios_key',
        androidApiKey: 'android_key',
      );

      expect(config.apiKeyForPlatform(TargetPlatform.iOS), 'ios_key');
      expect(config.apiKeyForPlatform(TargetPlatform.android), 'android_key');
      expect(config.apiKeyForPlatform(TargetPlatform.macOS), isEmpty);
    });

    test('apiKeyForCurrentPlatform honors explicit override', () {
      const config = RevenueCatEnvConfig(
        iosApiKey: 'ios_key',
        androidApiKey: 'android_key',
      );

      expect(
        config.apiKeyForCurrentPlatform(platform: TargetPlatform.android),
        'android_key',
      );
    });

    test('package IDs are provided in order', () {
      const config = RevenueCatEnvConfig(
        weeklyPackageId: 'weekly',
        monthlyPackageId: 'monthly',
        yearlyPackageId: 'yearly',
      );

      expect(config.packageIdsInDisplayOrder, ['weekly', 'monthly', 'yearly']);
    });

    test('defaults to empty API keys when not provided', () {
      const config = RevenueCatEnvConfig();

      expect(config.apiKeyForPlatform(TargetPlatform.iOS), isEmpty);
      expect(config.apiKeyForPlatform(TargetPlatform.android), isEmpty);
    });
  });
}
