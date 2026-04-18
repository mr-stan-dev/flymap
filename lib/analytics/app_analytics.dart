import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flymap/analytics/events/analytics_event.dart';

export 'package:flymap/analytics/events/analytics_event.dart';
export 'package:flymap/analytics/events/download_completed_event.dart';
export 'package:flymap/analytics/events/download_failed_event.dart';
export 'package:flymap/analytics/events/download_started_event.dart';
export 'package:flymap/analytics/events/onboarding_completed_event.dart';
export 'package:flymap/analytics/events/onboarding_started_event.dart';
export 'package:flymap/analytics/events/onboarding_step_completed_event.dart';
export 'package:flymap/analytics/events/onboarding_step_skipped_event.dart';
export 'package:flymap/analytics/events/onboarding_step_viewed_event.dart';
export 'package:flymap/analytics/events/paywall_result_event.dart';
export 'package:flymap/analytics/events/poi_download_completed_event.dart';
export 'package:flymap/analytics/events/poi_marker_tapped_event.dart';
export 'package:flymap/analytics/events/rate_prompt_action_event.dart';
export 'package:flymap/analytics/events/search_route_not_supported_event.dart';
export 'package:flymap/analytics/events/search_route_prepared_event.dart';

abstract class AppAnalytics {
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  });

  Future<void> setSubscriptionContext({required bool isPro});

  Future<void> log(AnalyticsEvent event);
}

class FirebaseAppAnalytics implements AppAnalytics {
  FirebaseAppAnalytics({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {
    try {
      await _analytics.setUserProperty(name: 'app_version', value: appVersion);
      await _analytics.setUserProperty(
        name: 'build_number',
        value: buildNumber,
      );
      await _analytics.setUserProperty(name: 'platform', value: platform);
      await _analytics.setUserProperty(name: 'app_env', value: appEnv);
    } catch (_) {
      // Keep analytics non-blocking for user flows.
    }
  }

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {
    try {
      await _analytics.setUserProperty(
        name: 'is_pro',
        value: isPro ? '1' : '0',
      );
    } catch (_) {
      // Keep analytics non-blocking for user flows.
    }
  }

  @override
  Future<void> log(AnalyticsEvent event) async {
    try {
      await _analytics.logEvent(name: event.name, parameters: event.parameters);
    } catch (_) {
      // Keep analytics non-blocking for user flows.
    }
  }
}
