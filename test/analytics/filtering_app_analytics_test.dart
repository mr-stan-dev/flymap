import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/analytics/app_analytics_identity.dart';
import 'package:flymap/analytics/filtering_app_analytics.dart';
import 'package:flymap/domain/entity/learn_access.dart';
import 'package:flymap/subscription/paywall_source.dart';

void main() {
  group('FilteringAppAnalytics', () {
    test('forwards allowed events and drops disallowed events', () async {
      final delegate = _RecordingAnalytics();
      final analytics = FilteringAppAnalytics(
        delegate: delegate,
        eventFilter: const _OnlyPaywallPresentedFilter(),
      );

      await analytics.log(
        const PaywallPresentedEvent(
          source: PaywallSource.settingsBanner,
          isProUser: false,
          hasProducts: true,
        ),
      );
      await analytics.log(
        const LearnArticleOpenedEvent(
          articleId: 'why_planes_turn',
          categoryId: 'flight_basics',
          access: LearnAccess.free,
          isProUser: false,
        ),
      );

      expect(
        delegate.events.whereType<FirebaseAnalyticsEvent>().map(
          (event) => event.firebaseEventName,
        ),
        <String>['paywall_presented'],
      );
    });

    test('still forwards sink setup identity and context calls', () async {
      final delegate = _RecordingAnalytics();
      final analytics = FilteringAppAnalytics(
        delegate: delegate,
        eventFilter: const _DenyAllFilter(),
      );

      await analytics.initialize();
      await analytics.setGlobalContext(
        appVersion: '1.0.0',
        buildNumber: '1',
        platform: 'ios',
        appEnv: 'release',
      );
      await analytics.setSubscriptionContext(isPro: true);
      await analytics.identifyUser(
        userId: 'firebase-uid',
        context: const AppAnalyticsGlobalContext(
          appVersion: '1.0.0',
          buildNumber: '1',
          platform: 'ios',
          appEnv: 'release',
        ),
      );

      expect(delegate.initialized, isTrue);
      expect(delegate.globalContext?['app_env'], 'release');
      expect(delegate.isPro, isTrue);
      expect(delegate.userId, 'firebase-uid');
    });
  });
}

class _OnlyPaywallPresentedFilter extends AppAnalyticsEventFilter {
  const _OnlyPaywallPresentedFilter();

  @override
  bool allows(AnalyticsEvent event) => event is PaywallPresentedEvent;
}

class _DenyAllFilter extends AppAnalyticsEventFilter {
  const _DenyAllFilter();

  @override
  bool allows(AnalyticsEvent event) => false;
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
