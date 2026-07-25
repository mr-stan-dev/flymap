import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/analytics/app_analytics_identity.dart';

export 'package:flymap/analytics/events/analytics_event.dart';
export 'package:flymap/analytics/events/download/download_completed_event.dart';
export 'package:flymap/analytics/events/download/download_failed_event.dart';
export 'package:flymap/analytics/events/download/download_started_event.dart';
export 'package:flymap/analytics/events/flight/flight_number_lookup_result_event.dart';
export 'package:flymap/analytics/events/flight/flight_opened_event.dart';
export 'package:flymap/analytics/events/subscription/flight_unlock_action_event.dart';
export 'package:flymap/analytics/events/subscription/flight_unlock_purchase_result_event.dart';
export 'package:flymap/analytics/events/subscription/real_route_choice_event.dart';
export 'package:flymap/analytics/events/subscription/flight_unlock_sheet_opened_event.dart';
export 'package:flymap/analytics/events/learn/geo_quiz_completed_event.dart';
export 'package:flymap/analytics/events/learn/geo_quiz_list_opened_event.dart';
export 'package:flymap/analytics/events/learn/geo_quiz_started_event.dart';
export 'package:flymap/analytics/events/learn/learn_article_opened_event.dart';
export 'package:flymap/analytics/events/learn/learn_category_opened_event.dart';
export 'package:flymap/analytics/events/onboarding/onboarding_completed_event.dart';
export 'package:flymap/analytics/events/onboarding/onboarding_started_event.dart';
export 'package:flymap/analytics/events/onboarding/onboarding_step_completed_event.dart';
export 'package:flymap/analytics/events/onboarding/onboarding_step_skipped_event.dart';
export 'package:flymap/analytics/events/onboarding/onboarding_step_viewed_event.dart';
export 'package:flymap/analytics/events/subscription/paywall_presented_event.dart';
export 'package:flymap/analytics/events/subscription/paywall_result_event.dart';
export 'package:flymap/analytics/events/engagement/poi_marker_tapped_event.dart';
export 'package:flymap/analytics/events/engagement/rate_prompt_action_event.dart';
export 'package:flymap/analytics/events/subscription/restore_purchases_result_event.dart';
export 'package:flymap/analytics/events/flight/route_overview_completed_event.dart';
export 'package:flymap/analytics/events/flight/route_type_selected_event.dart';
export 'package:flymap/analytics/events/flight/search_route_not_supported_event.dart';
export 'package:flymap/analytics/events/flight/search_route_prepared_event.dart';
export 'package:flymap/analytics/events/sharing/share_card_generated_event.dart';
export 'package:flymap/analytics/events/sharing/share_card_shared_event.dart';
export 'package:flymap/analytics/events/sky_camera/sky_camera_opened_event.dart';
export 'package:flymap/analytics/events/sky_camera/sky_photo_capture_event.dart';
export 'package:flymap/analytics/events/sky_camera/sky_video_capture_event.dart';
export 'package:flymap/analytics/events/sky_camera/sky_photo_share_event.dart';
export 'package:flymap/analytics/events/subscription/subscription_status_changed_event.dart';

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
