import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/auth/app_auth_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/revenuecat_client.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';
import 'package:flymap/subscription/revenuecat_identity_migration_store.dart';
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
          productId: 'flymap_pro',
          productPlanId: 'monthly-base',
        ),
      });

      final status = await repository.initialize();

      expect(client.configureCalls, 1);
      expect(status.isPro, isTrue);
      expect(status.entitlementId, 'pro');
      expect(status.expiresAt, expiration);
      expect(status.productId, 'flymap_pro');
      expect(status.productPlanId, 'monthly-base');
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

    test('configures RevenueCat without logging in a Firebase user', () async {
      await repository.initialize();

      expect(client.configureCalls, 1);
      expect(client.loggedInAppUserIds, isEmpty);
    });

    test('does not use Firebase uid when auth identity is disabled', () async {
      final identityClient = _FakeRevenueCatClient();
      final identityRepository = RevenueCatSubscriptionRepository(
        client: identityClient,
        config: const RevenueCatEnvConfig(
          androidApiKey: 'android_key',
          entitlementPro: 'pro',
        ),
        statusCache: _FakeSubscriptionStatusCache(),
        authRepository: _FakeAppAuthRepository(userId: 'firebase-uid'),
        analyticsContextStore: AppAnalyticsContextStore(),
        platformOverride: TargetPlatform.android,
      );
      addTearDown(identityRepository.close);

      await identityRepository.initialize();

      expect(identityClient.configuredAppUserIds, <String?>[null]);
      expect(identityClient.loggedInAppUserIds, isEmpty);
      expect(identityClient.attributes, isEmpty);
    });

    test(
      'configures RevenueCat anonymously before logging in Firebase uid',
      () async {
        final identityClient = _FakeRevenueCatClient();
        final identityCache = _FakeSubscriptionStatusCache();
        final contextStore = AppAnalyticsContextStore()
          ..setGlobal(
            const AppAnalyticsGlobalContext(
              appVersion: '1.2.3',
              buildNumber: '45',
              platform: 'android',
              appEnv: 'debug',
            ),
          );
        final identifiedRepository = RevenueCatSubscriptionRepository(
          client: identityClient,
          config: const RevenueCatEnvConfig(
            androidApiKey: 'android_key',
            entitlementPro: 'pro',
          ),
          statusCache: identityCache,
          identityMigrationStore: _FakeRevenueCatIdentityMigrationStore()
            ..alreadySynced = true,
          authRepository: _FakeAppAuthRepository(userId: 'firebase-uid'),
          analyticsContextStore: contextStore,
          authIdentityEnabled: true,
          platformOverride: TargetPlatform.android,
        );
        addTearDown(identifiedRepository.close);

        await identifiedRepository.initialize();

        expect(identityClient.configuredAppUserIds, <String?>[null]);
        expect(identityClient.loggedInAppUserIds, ['firebase-uid']);
        expect(
          identityClient.attributes,
          containsPair('firebase_uid', 'firebase-uid'),
        );
        expect(
          identityClient.attributes,
          containsPair('posthog_distinct_id', 'firebase-uid'),
        );
        expect(identityClient.attributes, containsPair('app_version', '1.2.3'));
        expect(identityClient.attributes, containsPair('platform', 'android'));
      },
    );

    test(
      'syncs purchases once after Firebase uid migration when first refresh is free',
      () async {
        final identityClient = _FakeRevenueCatClient();
        final migrationStore = _FakeRevenueCatIdentityMigrationStore();
        identityClient.getCustomerInfoResult = _snapshot({
          'pro': const RevenueCatEntitlementSnapshot(isActive: false),
        });
        identityClient.afterSyncCustomerInfoResult = _snapshot({
          'pro': const RevenueCatEntitlementSnapshot(isActive: true),
        });
        final identityRepository = RevenueCatSubscriptionRepository(
          client: identityClient,
          config: const RevenueCatEnvConfig(
            androidApiKey: 'android_key',
            entitlementPro: 'pro',
          ),
          statusCache: _FakeSubscriptionStatusCache(),
          identityMigrationStore: migrationStore,
          authRepository: _FakeAppAuthRepository(userId: 'firebase-uid'),
          authIdentityEnabled: true,
          platformOverride: TargetPlatform.android,
        );
        addTearDown(identityRepository.close);

        final status = await identityRepository.initialize();

        expect(identityClient.syncPurchasesCalls, 1);
        expect(migrationStore.checkedUserIds, ['firebase-uid']);
        expect(migrationStore.markedUserIds, ['firebase-uid']);
        expect(status.isPro, isTrue);
      },
    );

    test(
      'does not sync purchases when migrated Firebase uid is already pro',
      () async {
        final identityClient = _FakeRevenueCatClient();
        identityClient.getCustomerInfoResult = _snapshot({
          'pro': const RevenueCatEntitlementSnapshot(isActive: true),
        });
        final identityRepository = RevenueCatSubscriptionRepository(
          client: identityClient,
          config: const RevenueCatEnvConfig(
            androidApiKey: 'android_key',
            entitlementPro: 'pro',
          ),
          statusCache: _FakeSubscriptionStatusCache(),
          identityMigrationStore: _FakeRevenueCatIdentityMigrationStore(),
          authRepository: _FakeAppAuthRepository(userId: 'firebase-uid'),
          authIdentityEnabled: true,
          platformOverride: TargetPlatform.android,
        );
        addTearDown(identityRepository.close);

        final status = await identityRepository.initialize();

        expect(status.isPro, isTrue);
        expect(identityClient.syncPurchasesCalls, 0);
      },
    );

    test(
      'does not sync purchases again after migration marker is set',
      () async {
        final identityClient = _FakeRevenueCatClient();
        identityClient.getCustomerInfoResult = _snapshot({
          'pro': const RevenueCatEntitlementSnapshot(isActive: false),
        });
        final migrationStore = _FakeRevenueCatIdentityMigrationStore()
          ..alreadySynced = true;
        final identityRepository = RevenueCatSubscriptionRepository(
          client: identityClient,
          config: const RevenueCatEnvConfig(
            androidApiKey: 'android_key',
            entitlementPro: 'pro',
          ),
          statusCache: _FakeSubscriptionStatusCache(),
          identityMigrationStore: migrationStore,
          authRepository: _FakeAppAuthRepository(userId: 'firebase-uid'),
          authIdentityEnabled: true,
          platformOverride: TargetPlatform.android,
        );
        addTearDown(identityRepository.close);

        final status = await identityRepository.initialize();

        expect(status.isPro, isFalse);
        expect(identityClient.syncPurchasesCalls, 0);
        expect(migrationStore.checkedUserIds, ['firebase-uid']);
        expect(migrationStore.markedUserIds, isEmpty);
      },
    );

    test(
      'does not log in again when RevenueCat already has Firebase uid',
      () async {
        final identityClient = _FakeRevenueCatClient()
          ..currentAppUserId = 'firebase-uid';
        final identityRepository = RevenueCatSubscriptionRepository(
          client: identityClient,
          config: const RevenueCatEnvConfig(
            androidApiKey: 'android_key',
            entitlementPro: 'pro',
          ),
          statusCache: _FakeSubscriptionStatusCache(),
          authRepository: _FakeAppAuthRepository(userId: 'firebase-uid'),
          analyticsContextStore: AppAnalyticsContextStore(),
          authIdentityEnabled: true,
          platformOverride: TargetPlatform.android,
        );
        addTearDown(identityRepository.close);

        await identityRepository.initialize();

        expect(identityClient.configuredAppUserIds, <String?>[null]);
        expect(identityClient.loggedInAppUserIds, isEmpty);
        expect(
          identityClient.attributes,
          containsPair('firebase_uid', 'firebase-uid'),
        );
      },
    );

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

    test('paywall is not presented when billing is unavailable', () async {
      await repository.initialize();
      client.canMakePaymentsValue = false;

      final result = await repository.presentPaywallIfNeeded();

      expect(result, SubscriptionPaywallResult.notPresented);
      expect(client.presentPaywallCalls, 0);
      expect(repository.currentStatus.error, isNotEmpty);
    });

    test('purchase is blocked when billing is unavailable', () async {
      await repository.initialize();
      client.canMakePaymentsValue = false;

      final status = await repository.purchasePackage(packageId: 'monthly');

      expect(status.isPro, isFalse);
      expect(status.error, isNotEmpty);
      expect(client.purchaseCalls, 0);
    });

    test('loads products ordered by configured package IDs', () async {
      client.products = const [
        RevenueCatProductSnapshot(
          packageId: 'yearly',
          productId: 'yearly',
          title: 'Yearly',
          priceText: r'$39.99',
          description: 'yearly plan',
          subscriptionPeriod: 'P1Y',
        ),
        RevenueCatProductSnapshot(
          packageId: 'weekly',
          productId: 'weekly',
          title: 'Weekly',
          priceText: r'$2.99',
          description: 'weekly plan',
          subscriptionPeriod: 'P1W',
        ),
        RevenueCatProductSnapshot(
          packageId: 'monthly',
          productId: 'monthly',
          title: 'Monthly',
          priceText: r'$9.99',
          description: 'monthly plan',
          productPlanId: 'monthly-base',
          subscriptionPeriod: 'P1M',
        ),
      ];

      await repository.initialize();
      final products = await repository.getProducts();

      expect(products.map((e) => e.packageId), ['weekly', 'monthly', 'yearly']);
      expect(products.map((e) => e.subscriptionPeriod), ['P1W', 'P1M', 'P1Y']);
      expect(products[1].productPlanId, 'monthly-base');
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
  int presentPaywallCalls = 0;
  int purchaseCalls = 0;
  int syncPurchasesCalls = 0;
  bool throwOnConfigure = false;
  bool throwOnGetCustomerInfo = false;
  bool throwOnSyncPurchases = false;
  bool canMakePaymentsValue = true;
  RevenueCatCustomerSnapshot getCustomerInfoResult =
      const RevenueCatCustomerSnapshot(entitlements: {});
  RevenueCatCustomerSnapshot? afterSyncCustomerInfoResult;
  RevenueCatCustomerSnapshot restoreResult = const RevenueCatCustomerSnapshot(
    entitlements: {},
  );
  SubscriptionPaywallResult paywallResult =
      SubscriptionPaywallResult.notPresented;
  List<RevenueCatProductSnapshot> products = const [];
  RevenueCatStoreProductSnapshot? nonSubscriptionProduct;
  String currentAppUserId = r'$RCAnonymousID:test';
  bool adoptConfiguredAppUserId = true;
  final List<String?> configuredAppUserIds = <String?>[];
  final List<String> loggedInAppUserIds = <String>[];
  final Map<String, String> attributes = <String, String>{};

  @override
  Stream<RevenueCatCustomerSnapshot> get customerInfoStream =>
      _controller.stream;

  @override
  Future<void> close() async {
    await _controller.close();
  }

  @override
  Future<void> configure({required String apiKey, String? appUserId}) async {
    if (throwOnConfigure) {
      throw StateError('configure failed');
    }
    configureCalls++;
    configuredAppUserIds.add(appUserId);
    if (appUserId != null && adoptConfiguredAppUserId) {
      currentAppUserId = appUserId;
    }
  }

  @override
  Future<String> getAppUserId() async => currentAppUserId;

  @override
  Future<RevenueCatCustomerSnapshot> getCustomerInfo() async {
    if (throwOnGetCustomerInfo) {
      throw StateError('getCustomerInfo failed');
    }
    return getCustomerInfoResult;
  }

  @override
  Future<void> logIn({required String appUserId}) async {
    currentAppUserId = appUserId;
    loggedInAppUserIds.add(appUserId);
  }

  @override
  Future<void> setAttributes(Map<String, String> attributes) async {
    this.attributes.addAll(attributes);
  }

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded({
    required String entitlementId,
  }) async {
    presentPaywallCalls++;
    return paywallResult;
  }

  @override
  Future<bool> canMakePayments() async {
    return canMakePaymentsValue;
  }

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<List<RevenueCatProductSnapshot>> getCurrentOfferingProducts() async {
    return products;
  }

  @override
  Future<RevenueCatStoreProductSnapshot?> getNonSubscriptionProduct({
    required String productId,
  }) async {
    return nonSubscriptionProduct;
  }

  @override
  Future<RevenueCatCustomerSnapshot> purchasePackage({
    required String packageId,
  }) async {
    purchaseCalls++;
    return getCustomerInfoResult;
  }

  @override
  Future<void> purchaseNonSubscriptionProduct({
    required String productId,
  }) async {
    purchaseCalls++;
  }

  @override
  Future<RevenueCatCustomerSnapshot> restorePurchases() async {
    return restoreResult;
  }

  @override
  Future<void> syncPurchases() async {
    if (throwOnSyncPurchases) {
      throw StateError('syncPurchases failed');
    }
    syncPurchasesCalls++;
    final afterSync = afterSyncCustomerInfoResult;
    if (afterSync != null) {
      getCustomerInfoResult = afterSync;
    }
  }

  void emitSnapshot(RevenueCatCustomerSnapshot snapshot) {
    _controller.add(snapshot);
  }
}

class _FakeAppAuthRepository implements AppAuthRepository {
  _FakeAppAuthRepository({required this.userId});

  final String userId;

  @override
  String? get currentUserId => userId;

  @override
  Future<String> ensureSignedIn() async => userId;

  @override
  Future<String?> initialize() async => userId;
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

class _FakeRevenueCatIdentityMigrationStore
    implements RevenueCatIdentityMigrationStore {
  bool alreadySynced = false;
  final checkedUserIds = <String>[];
  final markedUserIds = <String>[];

  @override
  Future<bool> hasSyncedPurchasesForUser(String appUserId) async {
    checkedUserIds.add(appUserId);
    return alreadySynced;
  }

  @override
  Future<void> markSyncedPurchasesForUser(String appUserId) async {
    markedUserIds.add(appUserId);
    alreadySynced = true;
  }
}
