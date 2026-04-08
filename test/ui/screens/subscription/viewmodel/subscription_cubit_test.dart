import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

void main() {
  group('SubscriptionCubit', () {
    late _FakeSubscriptionRepository repository;
    late _FakeAppAnalytics analytics;
    late SubscriptionCubit cubit;

    setUp(() {
      repository = _FakeSubscriptionRepository();
      analytics = _FakeAppAnalytics();
      cubit = SubscriptionCubit(repository: repository, analytics: analytics);
    });

    tearDown(() async {
      await cubit.close();
      await repository.close();
    });

    test('startup transitions unknown -> loading -> pro', () async {
      repository.initializeResult = _status(isPro: true);
      final emitted = <SubscriptionState>[];
      final sub = cubit.stream.listen(emitted.add);
      addTearDown(sub.cancel);

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first.phase, SubscriptionPhase.loading);
      expect(
        emitted.map((state) => state.phase),
        contains(SubscriptionPhase.pro),
      );
      expect(cubit.state.phase, SubscriptionPhase.pro);
      expect(cubit.state.isPro, isTrue);
    });

    test('startup failure path is non-blocking and free', () async {
      repository.initializeResult = _status(
        isPro: false,
        error: 'Subscription service is temporarily unavailable.',
      );

      await cubit.initialize();

      expect(cubit.state.phase, SubscriptionPhase.free);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('startup keeps pro phase when status has error', () async {
      repository.initializeResult = _status(
        isPro: true,
        error: 'Failed to refresh subscription status.',
      );

      await cubit.initialize();

      expect(cubit.state.phase, SubscriptionPhase.pro);
      expect(cubit.state.errorMessage, isNotEmpty);
    });

    test('refresh and restore update state', () async {
      repository.refreshResult = _status(isPro: false);
      await cubit.refresh();
      expect(cubit.state.phase, SubscriptionPhase.free);

      repository.restoreResult = _status(isPro: true);
      await cubit.restorePurchases();
      expect(cubit.state.phase, SubscriptionPhase.pro);
    });

    test('stream updates propagate into cubit state', () async {
      repository.emit(_status(isPro: true));

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.phase, SubscriptionPhase.pro);
    });

    test('loadProducts updates products in state', () async {
      repository.products = const [
        SubscriptionProduct(
          packageId: 'weekly',
          productId: 'weekly',
          title: 'Weekly',
          priceText: r'$2.99',
        ),
      ];

      await cubit.loadProducts();

      expect(cubit.state.products, hasLength(1));
      expect(cubit.state.products.first.packageId, 'weekly');
    });

    test('maps create-flight source for wiki-only gate', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      await cubit.presentPaywallForCreateFlight(
        shouldUpgradeForArticles: true,
        shouldUpgradeForMapConfig: false,
      );

      final event = analytics.events.single as PaywallResultEvent;
      expect(event.source, PaywallSource.wikiLimit);
      expect(event.result, SubscriptionPaywallResult.cancelled);
    });

    test('maps create-flight source for map-only gate', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      await cubit.presentPaywallForCreateFlight(
        shouldUpgradeForArticles: false,
        shouldUpgradeForMapConfig: true,
      );

      final event = analytics.events.single as PaywallResultEvent;
      expect(event.source, PaywallSource.mapPro);
      expect(event.result, SubscriptionPaywallResult.cancelled);
    });

    test('maps create-flight source for combined gate', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      await cubit.presentPaywallForCreateFlight(
        shouldUpgradeForArticles: true,
        shouldUpgradeForMapConfig: true,
      );

      final event = analytics.events.single as PaywallResultEvent;
      expect(event.source, PaywallSource.wikiAndMapPro);
      expect(event.result, SubscriptionPaywallResult.cancelled);
    });

    test('logs settings paywall result and refreshes on purchased', () async {
      repository.paywallResult = SubscriptionPaywallResult.purchased;

      final result = await cubit.presentPaywallFromSettings();

      expect(result, SubscriptionPaywallResult.purchased);
      expect(repository.refreshCallCount, 1);
      final event = analytics.events.single as PaywallResultEvent;
      expect(event.source, PaywallSource.settingsBanner);
      expect(event.result, SubscriptionPaywallResult.purchased);
    });

    test(
      'logs subscription-management paywall result without refresh on cancelled',
      () async {
        repository.paywallResult = SubscriptionPaywallResult.cancelled;

        final result = await cubit.presentPaywallFromSubscriptionManagement();

        expect(result, SubscriptionPaywallResult.cancelled);
        expect(repository.refreshCallCount, 0);
        final event = analytics.events.single as PaywallResultEvent;
        expect(event.source, PaywallSource.subscriptionManagement);
        expect(event.result, SubscriptionPaywallResult.cancelled);
      },
    );

    test('logs POI section paywall source', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      final result = await cubit.presentPaywallFromOverviewPoi();

      expect(result, SubscriptionPaywallResult.cancelled);
      final event = analytics.events.single as PaywallResultEvent;
      expect(event.source, PaywallSource.poiSection);
      expect(event.result, SubscriptionPaywallResult.cancelled);
    });
  });
}

SubscriptionStatus _status({required bool isPro, String? error}) {
  return SubscriptionStatus(
    isPro: isPro,
    entitlementId: 'pro',
    lastUpdatedAt: DateTime.now(),
    error: error,
  );
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  final _controller = StreamController<SubscriptionStatus>.broadcast();

  SubscriptionStatus initializeResult = _status(isPro: false);
  SubscriptionStatus refreshResult = _status(isPro: false);
  SubscriptionStatus restoreResult = _status(isPro: false);
  SubscriptionPaywallResult paywallResult =
      SubscriptionPaywallResult.notPresented;
  int refreshCallCount = 0;
  List<SubscriptionProduct> products = const [];

  @override
  SubscriptionStatus get currentStatus => initializeResult;

  @override
  Stream<SubscriptionStatus> get statusStream => _controller.stream;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<SubscriptionStatus> initialize() async => initializeResult;

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async {
    return paywallResult;
  }

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<List<SubscriptionProduct>> getProducts() async => products;

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async {
    return _status(isPro: true);
  }

  @override
  Future<SubscriptionStatus> refresh() async {
    refreshCallCount++;
    return refreshResult;
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async => restoreResult;

  void emit(SubscriptionStatus status) {
    _controller.add(status);
  }
}

class _FakeAppAnalytics implements AppAnalytics {
  final List<AnalyticsEvent> events = <AnalyticsEvent>[];

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}

  @override
  Future<void> log(AnalyticsEvent event) async {
    events.add(event);
  }
}
