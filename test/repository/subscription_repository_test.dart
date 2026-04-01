import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/revenuecat_client.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/subscription/subscription_status_cache.dart';

void main() {
  group('RevenueCatSubscriptionRepository', () {
    late _FakeRevenueCatClient client;
    late _FakeSubscriptionStatusCache cache;
    late RevenueCatSubscriptionRepository repository;

    setUp(() {
      client = _FakeRevenueCatClient();
      cache = _FakeSubscriptionStatusCache();
      repository = RevenueCatSubscriptionRepository(
        client: client,
        config: const RevenueCatEnvConfig(
          androidApiKey: 'android_key',
          entitlementPro: 'pro',
        ),
        statusCache: cache,
        platformOverride: TargetPlatform.android,
      );
    });

    tearDown(() async {
      await repository.close();
    });

    test('initializes and maps active entitlement to pro', () async {
      final expiration = DateTime.parse('2026-12-01T00:00:00Z');
      client.getCustomerInfoResult = _snapshot({
        'pro': RevenueCatEntitlementSnapshot(
          isActive: true,
          expirationDate: expiration,
        ),
      });

      final status = await repository.initialize();

      expect(client.configureCalls, 1);
      expect(status.isPro, isTrue);
      expect(status.entitlementId, 'pro');
      expect(status.expiresAt, expiration);
      expect(status.error, isNull);
    });

    test('maps missing entitlement to free', () async {
      client.getCustomerInfoResult = _snapshot({
        'other': const RevenueCatEntitlementSnapshot(isActive: true),
      });

      final status = await repository.initialize();

      expect(status.isPro, isFalse);
      expect(status.error, isNull);
    });

    test('returns cached status with error when API key is missing', () async {
      cache.loaded = SubscriptionStatus(
        isPro: true,
        entitlementId: 'pro',
        lastUpdatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      final noKeyRepository = RevenueCatSubscriptionRepository(
        client: client,
        config: const RevenueCatEnvConfig(
          iosApiKey: '',
          androidApiKey: '',
          entitlementPro: 'pro',
        ),
        statusCache: cache,
        platformOverride: TargetPlatform.android,
      );
      addTearDown(noKeyRepository.close);

      final status = await noKeyRepository.initialize();

      expect(client.configureCalls, 0);
      expect(status.isPro, isTrue);
      expect(status.error, isNotEmpty);
    });

    test(
      'returns free with error when API key is missing and cache is empty',
      () async {
        final emptyCache = _FakeSubscriptionStatusCache();
        final noKeyRepository = RevenueCatSubscriptionRepository(
          client: client,
          config: const RevenueCatEnvConfig(
            iosApiKey: '',
            androidApiKey: '',
            entitlementPro: 'pro',
          ),
          statusCache: emptyCache,
          platformOverride: TargetPlatform.android,
        );
        addTearDown(noKeyRepository.close);

        final status = await noKeyRepository.initialize();

        expect(status.isPro, isFalse);
        expect(status.error, isNotEmpty);
      },
    );

    test('refresh failure keeps previous pro status', () async {
      client.getCustomerInfoResult = _snapshot({
        'pro': const RevenueCatEntitlementSnapshot(isActive: true),
      });
      await repository.initialize();

      client.throwOnGetCustomerInfo = true;
      final status = await repository.refresh();

      expect(status.isPro, isTrue);
      expect(status.error, isNotEmpty);
    });

    test('refresh handles client failure and remains non-pro', () async {
      client.getCustomerInfoResult = _snapshot({
        'pro': const RevenueCatEntitlementSnapshot(isActive: false),
      });
      await repository.initialize();

      client.throwOnGetCustomerInfo = true;
      final status = await repository.refresh();

      expect(status.isPro, isFalse);
      expect(status.error, isNotEmpty);
    });

    test(
      'loads cached status before configure and keeps it on init failure',
      () async {
        cache.loaded = SubscriptionStatus(
          isPro: true,
          entitlementId: 'pro',
          lastUpdatedAt: DateTime.parse('2026-02-01T00:00:00Z'),
        );
        client.throwOnConfigure = true;

        final status = await repository.initialize();

        expect(status.isPro, isTrue);
        expect(status.error, isNotEmpty);
      },
    );

    test('forwards customer info stream updates', () async {
      client.getCustomerInfoResult = _snapshot({
        'pro': const RevenueCatEntitlementSnapshot(isActive: false),
      });
      await repository.initialize();

      final emitted = <bool>[];
      final sub = repository.statusStream.listen((status) {
        emitted.add(status.isPro);
      });
      addTearDown(sub.cancel);

      client.emitSnapshot(
        _snapshot({'pro': const RevenueCatEntitlementSnapshot(isActive: true)}),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, contains(true));
    });

    test('paywall purchased triggers refresh and updates status', () async {
      client.getCustomerInfoResult = _snapshot({
        'pro': const RevenueCatEntitlementSnapshot(isActive: false),
      });
      await repository.initialize();

      client.paywallResult = SubscriptionPaywallResult.purchased;
      client.getCustomerInfoResult = _snapshot({
        'pro': const RevenueCatEntitlementSnapshot(isActive: true),
      });

      final result = await repository.presentPaywallIfNeeded();

      expect(result, SubscriptionPaywallResult.purchased);
      expect(repository.currentStatus.isPro, isTrue);
    });

    test('loads products ordered by configured package IDs', () async {
      client.products = const [
        RevenueCatProductSnapshot(
          packageId: 'yearly',
          productId: 'yearly',
          title: 'Yearly',
          priceText: r'$39.99',
          description: 'yearly plan',
        ),
        RevenueCatProductSnapshot(
          packageId: 'weekly',
          productId: 'weekly',
          title: 'Weekly',
          priceText: r'$2.99',
          description: 'weekly plan',
        ),
        RevenueCatProductSnapshot(
          packageId: 'monthly',
          productId: 'monthly',
          title: 'Monthly',
          priceText: r'$9.99',
          description: 'monthly plan',
        ),
      ];

      await repository.initialize();
      final products = await repository.getProducts();

      expect(products.map((e) => e.packageId), ['weekly', 'monthly', 'yearly']);
    });

    test('persists last successful status to cache', () async {
      client.getCustomerInfoResult = _snapshot({
        'pro': const RevenueCatEntitlementSnapshot(isActive: true),
      });

      final status = await repository.initialize();

      expect(status.isPro, isTrue);
      expect(cache.saved, isNotNull);
      expect(cache.saved?.isPro, isTrue);
      expect(cache.saved?.entitlementId, 'pro');
    });
  });
}

RevenueCatCustomerSnapshot _snapshot(
  Map<String, RevenueCatEntitlementSnapshot> entitlements,
) {
  return RevenueCatCustomerSnapshot(entitlements: entitlements);
}

class _FakeRevenueCatClient implements RevenueCatClient {
  final _controller = StreamController<RevenueCatCustomerSnapshot>.broadcast();

  int configureCalls = 0;
  bool throwOnConfigure = false;
  bool throwOnGetCustomerInfo = false;
  RevenueCatCustomerSnapshot getCustomerInfoResult =
      const RevenueCatCustomerSnapshot(entitlements: {});
  RevenueCatCustomerSnapshot restoreResult = const RevenueCatCustomerSnapshot(
    entitlements: {},
  );
  SubscriptionPaywallResult paywallResult =
      SubscriptionPaywallResult.notPresented;
  List<RevenueCatProductSnapshot> products = const [];

  @override
  Stream<RevenueCatCustomerSnapshot> get customerInfoStream =>
      _controller.stream;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<void> configure({required String apiKey}) async {
    if (throwOnConfigure) {
      throw StateError('configure failed');
    }
    configureCalls++;
  }

  @override
  Future<RevenueCatCustomerSnapshot> getCustomerInfo() async {
    if (throwOnGetCustomerInfo) {
      throw StateError('getCustomerInfo failed');
    }
    return getCustomerInfoResult;
  }

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded({
    required String entitlementId,
  }) async {
    return paywallResult;
  }

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<List<RevenueCatProductSnapshot>> getCurrentOfferingProducts() async {
    return products;
  }

  @override
  Future<RevenueCatCustomerSnapshot> purchasePackage({
    required String packageId,
  }) async {
    return getCustomerInfoResult;
  }

  @override
  Future<RevenueCatCustomerSnapshot> restorePurchases() async {
    return restoreResult;
  }

  void emitSnapshot(RevenueCatCustomerSnapshot snapshot) {
    _controller.add(snapshot);
  }
}

class _FakeSubscriptionStatusCache implements SubscriptionStatusCache {
  SubscriptionStatus? loaded;
  SubscriptionStatus? saved;

  @override
  Future<SubscriptionStatus?> load() async {
    return loaded;
  }

  @override
  Future<void> save(SubscriptionStatus status) async {
    saved = status;
  }
}
