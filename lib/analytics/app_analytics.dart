import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/analytics/app_analytics_identity.dart';

export 'package:flymap/analytics/events/analytics_event.dart';
export 'package:flymap/analytics/events/download_completed_event.dart';
export 'package:flymap/analytics/events/download_failed_event.dart';
export 'package:flymap/analytics/events/download_started_event.dart';
export 'package:flymap/analytics/events/flight_number_lookup_result_event.dart';
export 'package:flymap/analytics/events/flight_opened_event.dart';
export 'package:flymap/analytics/events/flight_unlock_action_event.dart';
export 'package:flymap/analytics/events/flight_unlock_purchase_result_event.dart';
export 'package:flymap/analytics/events/flight_unlock_sheet_opened_event.dart';
export 'package:flymap/analytics/events/geo_quiz_completed_event.dart';
export 'package:flymap/analytics/events/geo_quiz_list_opened_event.dart';
export 'package:flymap/analytics/events/geo_quiz_started_event.dart';
export 'package:flymap/analytics/events/learn_article_opened_event.dart';
export 'package:flymap/analytics/events/learn_category_opened_event.dart';
export 'package:flymap/analytics/events/onboarding_completed_event.dart';
export 'package:flymap/analytics/events/onboarding_started_event.dart';
export 'package:flymap/analytics/events/onboarding_step_completed_event.dart';
export 'package:flymap/analytics/events/onboarding_step_skipped_event.dart';
export 'package:flymap/analytics/events/onboarding_step_viewed_event.dart';
export 'package:flymap/analytics/events/paywall_presented_event.dart';
export 'package:flymap/analytics/events/paywall_result_event.dart';
export 'package:flymap/analytics/events/poi_marker_tapped_event.dart';
export 'package:flymap/analytics/events/rate_prompt_action_event.dart';
export 'package:flymap/analytics/events/restore_purchases_result_event.dart';
export 'package:flymap/analytics/events/route_overview_completed_event.dart';
export 'package:flymap/analytics/events/route_type_selected_event.dart';
export 'package:flymap/analytics/events/search_route_not_supported_event.dart';
export 'package:flymap/analytics/events/search_route_prepared_event.dart';
export 'package:flymap/analytics/events/share_card_generated_event.dart';
export 'package:flymap/analytics/events/share_card_shared_event.dart';
export 'package:flymap/analytics/events/sky_camera_opened_event.dart';
export 'package:flymap/analytics/events/sky_photo_capture_event.dart';
export 'package:flymap/analytics/events/sky_photo_share_event.dart';
export 'package:flymap/analytics/events/subscription_status_changed_event.dart';

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

class FirebaseAppAnalytics
    implements AppAnalytics, UserIdentifyingAppAnalytics {
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
  Future<void> identifyUser({
    required String userId,
    required AppAnalyticsGlobalContext context,
    Map<String, Object> properties = const <String, Object>{},
    Map<String, Object> setOnceProperties = const <String, Object>{},
  }) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (_) {
      // Keep analytics non-blocking for user flows.
    }
  }

  @override
  Future<void> log(AnalyticsEvent event) async {
    if (event is! FirebaseAnalyticsEvent) return;
    try {
      await _analytics.logEvent(
        name: event.firebaseEventName,
        parameters: _firebaseParameters(event.firebaseParameters),
      );
    } catch (_) {
      // Keep analytics non-blocking for user flows.
    }
  }

  Map<String, Object> _firebaseParameters(Map<String, Object> parameters) {
    return parameters.map((key, value) {
      return MapEntry(key, value is bool ? (value ? 1 : 0) : value);
    });
  }
}
