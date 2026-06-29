import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/analytics/app_analytics_identity.dart';
import 'package:flymap/analytics/composite_app_analytics.dart';

void main() {
  group('CompositeAppAnalytics', () {
    test('forwards calls to all sinks', () async {
      final first = _RecordingAnalytics();
      final second = _RecordingAnalytics();
      final analytics = CompositeAppAnalytics(sinks: [first, second]);

      await analytics.initialize();
      await analytics.setGlobalContext(
        appVersion: '1.0.0',
        buildNumber: '1',
        platform: 'ios',
        appEnv: 'debug',
      );
      await analytics.setSubscriptionContext(isPro: true);
      await analytics.identifyUser(
        userId: 'firebase-uid',
        context: const AppAnalyticsGlobalContext(
          appVersion: '1.0.0',
          buildNumber: '1',
          platform: 'ios',
          appEnv: 'debug',
        ),
      );
      await analytics.log(
        const OnboardingStartedEvent(flowVersion: 'v1', entrySource: 'test'),
      );

      expect(first.initialized, isTrue);
      expect(second.initialized, isTrue);
      expect(first.globalContext?['app_version'], '1.0.0');
      expect(second.globalContext?['platform'], 'ios');
      expect(first.isPro, isTrue);
      expect(second.userId, 'firebase-uid');
      expect(
        (first.events.single as FirebaseAnalyticsEvent).firebaseEventName,
        'onboarding_started',
      );
      expect(
        (second.events.single as PostHogAnalyticsEvent).postHogEventName,
        'onboarding_started',
      );
    });

    test('swallows sink errors and still forwards to healthy sinks', () async {
      final failing = _ThrowingAnalytics();
      final healthy = _RecordingAnalytics();
      final analytics = CompositeAppAnalytics(sinks: [failing, healthy]);

      await analytics.initialize();
      await analytics.setSubscriptionContext(isPro: false);
      await analytics.log(
        const OnboardingStartedEvent(flowVersion: 'v1', entrySource: 'test'),
      );

      expect(healthy.initialized, isTrue);
      expect(healthy.isPro, isFalse);
      expect(
        (healthy.events.single as FirebaseAnalyticsEvent).firebaseEventName,
        'onboarding_started',
      );
    });
  });
}

class _RecordingAnalytics
    implements
        AppAnalytics,
        InitializableAppAnalytics,
        UserIdentifyingAppAnalytics {
  bool initialized = false;
  bool? isPro;
  String? userId;
  Map<String, Object>? globalContext;
  final List<AnalyticsEvent> events = <AnalyticsEvent>[];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> identifyUser({
    required String userId,
    required AppAnalyticsGlobalContext context,
    Map<String, Object> properties = const <String, Object>{},
    Map<String, Object> setOnceProperties = const <String, Object>{},
  }) async {
    this.userId = userId;
  }

  @override
  Future<void> log(AnalyticsEvent event) async {
    events.add(event);
  }

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {
    globalContext = <String, Object>{
      'app_version': appVersion,
      'build_number': buildNumber,
      'platform': platform,
      'app_env': appEnv,
    };
  }

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {
    this.isPro = isPro;
  }
}

class _ThrowingAnalytics
    implements
        AppAnalytics,
        InitializableAppAnalytics,
        UserIdentifyingAppAnalytics {
  @override
  Future<void> initialize() async => throw StateError('boom');

  @override
  Future<void> identifyUser({
    required String userId,
    required AppAnalyticsGlobalContext context,
    Map<String, Object> properties = const <String, Object>{},
    Map<String, Object> setOnceProperties = const <String, Object>{},
  }) async {
    throw StateError('boom');
  }

  @override
  Future<void> log(AnalyticsEvent event) async => throw StateError('boom');

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {
    throw StateError('boom');
  }

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {
    throw StateError('boom');
  }
}
