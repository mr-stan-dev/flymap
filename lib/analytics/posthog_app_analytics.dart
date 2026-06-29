import 'package:flutter/foundation.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/analytics/app_analytics_identity.dart';
import 'package:flymap/analytics/posthog_client.dart';
import 'package:flymap/analytics/posthog_env_config.dart';

class PostHogAppAnalytics
    implements
        AppAnalytics,
        InitializableAppAnalytics,
        UserIdentifyingAppAnalytics {
  PostHogAppAnalytics({
    required PostHogEnvConfig config,
    required PostHogAnalyticsClient client,
  }) : _config = config,
       _client = client;

  final PostHogEnvConfig _config;
  final PostHogAnalyticsClient _client;
  bool _isReady = false;
  AppAnalyticsGlobalContext _globalContext = AppAnalyticsGlobalContext.unknown;
  bool? _isPro;

  @override
  Future<void> initialize() async {
    if (!_config.isConfigured) return;
    await _client.setup(
      projectToken: _config.projectToken,
      host: _config.host,
      debug: kDebugMode,
      captureApplicationLifecycleEvents: false,
    );
    _isReady = true;
  }

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {
    _globalContext = AppAnalyticsGlobalContext(
      appVersion: appVersion,
      buildNumber: buildNumber,
      platform: platform,
      appEnv: appEnv,
    );
  }

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {
    _isPro = isPro;
    if (!_isReady) return;
    await _client.setPersonProperties(
      userPropertiesToSet: <String, Object>{
        'is_pro': isPro,
        'subscription_status': isPro ? 'pro' : 'free',
      },
    );
  }

  @override
  Future<void> identifyUser({
    required String userId,
    required AppAnalyticsGlobalContext context,
    Map<String, Object> properties = const <String, Object>{},
    Map<String, Object> setOnceProperties = const <String, Object>{},
  }) async {
    if (!_isReady) return;
    final currentProperties = <String, Object>{
      ...context.toAnalyticsProperties(),
      ...properties,
    };
    final isPro = _isPro;
    if (isPro != null) {
      currentProperties['is_pro'] = isPro;
      currentProperties['subscription_status'] = isPro ? 'pro' : 'free';
    }
    await _client.identify(
      userId: userId,
      userProperties: currentProperties,
      userPropertiesSetOnce: <String, Object>{
        'first_app_version': context.appVersion,
        'first_platform': context.platform,
        ...setOnceProperties,
      },
    );
  }

  @override
  Future<void> log(AnalyticsEvent event) async {
    if (event is! PostHogAnalyticsEvent) return;
    if (!_isReady) return;
    await _client.capture(
      eventName: event.postHogEventName,
      properties: <String, Object>{
        ..._globalContext.toAnalyticsProperties(),
        ...event.postHogParameters,
      },
    );
  }
}
