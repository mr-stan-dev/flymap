import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

void main() {
  group('SubscriptionCubit', () {
    late _FakeSubscriptionRepository repository;
    late _FakeFlightUnlockRepository flightUnlockRepository;
    late _FakeAppAnalytics analytics;
    late SubscriptionCubit cubit;

    setUp(() {
      repository = _FakeSubscriptionRepository();
      flightUnlockRepository = _FakeFlightUnlockRepository();
      analytics = _FakeAppAnalytics();
      cubit = SubscriptionCubit(
        repository: repository,
        flightUnlockRepository: flightUnlockRepository,
        analytics: analytics,
      );
    });

    tearDown(() async {
      await cubit.close();
      await repository.close();
      await flightUnlockRepository.close();
    });

    test('startup transitions unknown -> loading -> pro', () async {
      repository.initializeResult = _status(isPro: true);
      flightUnlockRepository.unusedCount = 2;
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
      expect(cubit.state.unusedFlightUnlockCount, 2);
    });

    test(
      'startup silently preloads unlock product when balance is empty',
      () async {
        flightUnlockRepository.product = const FlightUnlockProduct(
          productId: 'unlock.flight',
          title: 'Unlock Flight',
          priceText: r'$4.99',
        );

        await cubit.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(flightUnlockRepository.getUnlockProductCallCount, 1);
        expect(cubit.state.flightUnlockProduct?.priceText, r'$4.99');
        expect(cubit.state.flightUnlockErrorMessage, isNull);
      },
    );

    test(
      'startup silent preload does not expose error when product is unavailable',
      () async {
        await cubit.initialize();
        await Future<void>.delayed(Duration.zero);

        expect(flightUnlockRepository.getUnlockProductCallCount, 1);
        expect(cubit.state.flightUnlockProduct, isNull);
        expect(cubit.state.flightUnlockErrorMessage, isNull);
      },
    );

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

    test('loadFlightUnlockProduct updates unlock product state', () async {
      flightUnlockRepository.product = const FlightUnlockProduct(
        productId: 'unlock.flight',
        title: 'Unlock Flight',
        priceText: r'$4.99',
      );

      final product = await cubit.loadFlightUnlockProduct();

      expect(product?.productId, 'unlock.flight');
      expect(cubit.state.flightUnlockProduct?.priceText, r'$4.99');
      expect(cubit.state.isFlightUnlockLoading, isFalse);
    });

    test('purchaseFlightUnlock increments local balance', () async {
      flightUnlockRepository.purchaseResult =
          const FlightUnlockPurchaseResult.purchased(
            productId: 'unlock.flight',
          );

      final result = await cubit.purchaseFlightUnlock();

      expect(result.isPurchased, isTrue);
      expect(result.productId, 'unlock.flight');
      expect(cubit.state.unusedFlightUnlockCount, 1);
      expect(cubit.state.flightUnlockErrorMessage, isNull);
    });

    test('purchaseFlightUnlock exposes cancelled message', () async {
      flightUnlockRepository.purchaseResult =
          const FlightUnlockPurchaseResult.cancelled(
            productId: 'unlock.flight',
          );

      final result = await cubit.purchaseFlightUnlock();

      expect(result.status, FlightUnlockPurchaseStatus.cancelled);
      expect(result.productId, 'unlock.flight');
      expect(cubit.state.unusedFlightUnlockCount, 0);
      expect(cubit.state.flightUnlockErrorMessage, isNotEmpty);
    });

    test('clearFlightUnlockError removes transient unlock error', () async {
      flightUnlockRepository.purchaseResult =
          const FlightUnlockPurchaseResult.cancelled();

      await cubit.purchaseFlightUnlock();
      expect(cubit.state.flightUnlockErrorMessage, isNotEmpty);

      cubit.clearFlightUnlockError();

      expect(cubit.state.flightUnlockErrorMessage, isNull);
    });

    test('maps create-flight source for gate', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      await cubit.presentPaywallForCreateFlight();

      final presented = analytics.events
          .whereType<PaywallPresentedEvent>()
          .single;
      expect(presented.source, PaywallSource.wikiLimit);
      expect(presented.isProUser, isFalse);
      expect(presented.hasProducts, isFalse);
      final event = analytics.events.whereType<PaywallResultEvent>().single;
      expect(event.source, PaywallSource.wikiLimit);
      expect(event.result, SubscriptionPaywallResult.cancelled);
    });

    test('logs settings paywall result and refreshes on purchased', () async {
      repository.paywallResult = SubscriptionPaywallResult.purchased;

      final result = await cubit.presentPaywallFromSettings();

      expect(result, SubscriptionPaywallResult.purchased);
      expect(repository.refreshCallCount, 1);
      final event = analytics.events.whereType<PaywallResultEvent>().single;
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
        final event = analytics.events.whereType<PaywallResultEvent>().single;
        expect(event.source, PaywallSource.subscriptionManagement);
        expect(event.result, SubscriptionPaywallResult.cancelled);
      },
    );

    test('logs POI section paywall source', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      final result = await cubit.presentPaywallFromOverviewPoi();

      expect(result, SubscriptionPaywallResult.cancelled);
      final event = analytics.events.whereType<PaywallResultEvent>().single;
      expect(event.source, PaywallSource.poiSection);
      expect(event.result, SubscriptionPaywallResult.cancelled);
    });

    test('logs Geo Quiz paywall source', () async {
      repository.paywallResult = SubscriptionPaywallResult.purchased;

      final result = await cubit.presentPaywallFromGeoQuiz();

      expect(result, SubscriptionPaywallResult.purchased);
      final presented = analytics.events
          .whereType<PaywallPresentedEvent>()
          .single;
      expect(presented.source, PaywallSource.geoQuizLockedContent);
      final completed = analytics.events.whereType<PaywallResultEvent>().single;
      expect(completed.source, PaywallSource.geoQuizLockedContent);
      expect(completed.result, SubscriptionPaywallResult.purchased);
    });

    test('logs real route gate paywall source', () async {
      repository.paywallResult = SubscriptionPaywallResult.cancelled;

      final result = await cubit.presentPaywallFromRealRouteGate();

      expect(result, SubscriptionPaywallResult.cancelled);
      final event = analytics.events.whereType<PaywallResultEvent>().single;
      expect(event.source, PaywallSource.realRouteGate);
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

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  final _controller = StreamController<int>.broadcast();

  int unusedCount = 0;
  FlightUnlockProduct? product;
  FlightUnlockPurchaseResult purchaseResult =
      const FlightUnlockPurchaseResult.cancelled();
  int getUnlockProductCallCount = 0;

  @override
  Stream<int> get balanceStream => _controller.stream;

  @override
  int get currentUnusedUnlockCount => unusedCount;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<int> consumeUnlock() async {
    unusedCount = unusedCount > 0 ? unusedCount - 1 : 0;
    _controller.add(unusedCount);
    return unusedCount;
  }

  @override
  Future<FlightUnlockProduct?> getUnlockProduct() async {
    getUnlockProductCallCount++;
    return product;
  }

  @override
  Future<int> initialize() async {
    _controller.add(unusedCount);
    return unusedCount;
  }

  @override
  Future<FlightUnlockPurchaseResult> purchaseUnlock() async {
    if (purchaseResult.isPurchased) {
      unusedCount++;
      _controller.add(unusedCount);
    }
    return purchaseResult;
  }

  @override
  Future<int> restoreUnlock() async {
    unusedCount++;
    _controller.add(unusedCount);
    return unusedCount;
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
