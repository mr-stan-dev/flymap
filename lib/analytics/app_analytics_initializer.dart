import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppAnalyticsInitializer {
  const AppAnalyticsInitializer({required AppAnalytics analytics})
    : _analytics = analytics;

  final AppAnalytics _analytics;

  Future<void> initialize() async {
    final analyticsEnabled = kReleaseMode;
    var appVersion = 'unknown';
    var buildNumber = '0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
      buildNumber = packageInfo.buildNumber;
    } catch (_) {
      // Keep startup non-blocking if package info is unavailable.
    }

    await _analytics.setGlobalContext(
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: defaultTargetPlatform.name,
      appEnv: kReleaseMode
          ? 'release'
          : kProfileMode
          ? 'profile'
          : 'debug',
    );

    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
      analyticsEnabled,
    );
  }
}
