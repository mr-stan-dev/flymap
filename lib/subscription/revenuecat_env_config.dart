import 'package:flutter/foundation.dart';

class RevenueCatEnvConfig {
  const RevenueCatEnvConfig({
    this.iosApiKey = _defaultApiKey,
    this.androidApiKey = _defaultApiKey,
    this.entitlementPro = 'Flymap Pro',
    this.weeklyPackageId = 'weekly',
    this.monthlyPackageId = 'monthly',
    this.yearlyPackageId = 'yearly',
  });

  static const _defaultApiKey = 'test_xoDWuBlcmaxIARJzQkcHLnwgTDL';

  factory RevenueCatEnvConfig.fromEnvironment() {
    return const RevenueCatEnvConfig(
      iosApiKey: String.fromEnvironment(
        'RC_API_KEY_IOS',
        defaultValue: _defaultApiKey,
      ),
      androidApiKey: String.fromEnvironment(
        'RC_API_KEY_ANDROID',
        defaultValue: _defaultApiKey,
      ),
      entitlementPro: String.fromEnvironment(
        'RC_ENTITLEMENT_PRO',
        defaultValue: 'Flymap Pro',
      ),
      weeklyPackageId: String.fromEnvironment(
        'RC_PACKAGE_WEEKLY',
        defaultValue: 'weekly',
      ),
      monthlyPackageId: String.fromEnvironment(
        'RC_PACKAGE_MONTHLY',
        defaultValue: 'monthly',
      ),
      yearlyPackageId: String.fromEnvironment(
        'RC_PACKAGE_YEARLY',
        defaultValue: 'yearly',
      ),
    );
  }

  final String iosApiKey;
  final String androidApiKey;
  final String entitlementPro;
  final String weeklyPackageId;
  final String monthlyPackageId;
  final String yearlyPackageId;

  String get entitlementId {
    final value = entitlementPro.trim();
    return value.isEmpty ? 'Flymap Pro' : value;
  }

  List<String> get packageIdsInDisplayOrder {
    return [
      weeklyPackageId.trim(),
      monthlyPackageId.trim(),
      yearlyPackageId.trim(),
    ].where((id) => id.isNotEmpty).toList();
  }

  String apiKeyForPlatform(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
        return iosApiKey.trim();
      case TargetPlatform.android:
        return androidApiKey.trim();
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return '';
    }
  }

  String apiKeyForCurrentPlatform({TargetPlatform? platform}) {
    return apiKeyForPlatform(platform ?? defaultTargetPlatform);
  }
}
