import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/subscription/revenuecat_client.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status_cache.dart';
import 'package:flymap/subscription/subscription_status.dart';

abstract class SubscriptionRepository {
  Stream<SubscriptionStatus> get statusStream;

  SubscriptionStatus get currentStatus;

  Future<SubscriptionStatus> initialize();

  Future<SubscriptionStatus> refresh();

  Future<SubscriptionStatus> restorePurchases();

  Future<List<SubscriptionProduct>> getProducts();

  Future<SubscriptionStatus> purchasePackage({required String packageId});

  Future<SubscriptionPaywallResult> presentPaywallIfNeeded();

  Future<void> presentCustomerCenter();

  Future<void> close();
}

class RevenueCatSubscriptionRepository implements SubscriptionRepository {
  RevenueCatSubscriptionRepository({
    required RevenueCatClient client,
    required RevenueCatEnvConfig config,
    SubscriptionStatusCache? statusCache,
    TargetPlatform? platformOverride,
  }) : _client = client,
       _config = config,
       _statusCache = statusCache ?? _NoopSubscriptionStatusCache(),
       _platformOverride = platformOverride,
       _currentStatus = SubscriptionStatus(
         isPro: false,
         entitlementId: config.entitlementId,
         lastUpdatedAt: DateTime.now(),
       );

  final RevenueCatClient _client;
  final RevenueCatEnvConfig _config;
  final SubscriptionStatusCache _statusCache;
  final TargetPlatform? _platformOverride;
  final _logger = const Logger('SubscriptionRepository');

  final StreamController<SubscriptionStatus> _statusController =
      StreamController<SubscriptionStatus>.broadcast();

  StreamSubscription<RevenueCatCustomerSnapshot>? _customerInfoSubscription;
  Future<SubscriptionStatus>? _initializeTask;
  bool _isConfigured = false;
  SubscriptionStatus _currentStatus;

  @override
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;

  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  @override
  Future<SubscriptionStatus> initialize() {
    final existing = _initializeTask;
    if (existing != null) return existing;

    final task = _initializeInternal();
    _initializeTask = task;
    return task.whenComplete(() {
      _initializeTask = null;
    });
  }

  Future<SubscriptionStatus> _initializeInternal() async {
    final cached = await _statusCache.load();
    if (cached != null) {
      _publish(cached, persist: false);
    }

    final apiKey = _config.apiKeyForCurrentPlatform(
      platform: _platformOverride,
    );
    if (apiKey.isEmpty) {
      _logger.error(
        'RevenueCat API key is missing for this platform. '
        'Set RC_API_KEY_IOS / RC_API_KEY_ANDROID.',
      );
      return _publishError(
        'RevenueCat API key is missing for this platform. '
        'Set RC_API_KEY_IOS / RC_API_KEY_ANDROID.',
      );
    }

    try {
      await _client.configure(apiKey: apiKey);
      _isConfigured = true;
      _ensureCustomerInfoSubscription();
      return refresh();
    } catch (e) {
      _logger.error('RevenueCat configure failed: $e');
      _isConfigured = false;
      return _publishError('Subscription service is temporarily unavailable.');
    }
  }

  @override
  Future<SubscriptionStatus> refresh() async {
    if (!_isConfigured) {
      await initialize();
      if (!_isConfigured) return _currentStatus;
    }

    try {
      final snapshot = await _client.getCustomerInfo();
      return _publish(_toStatus(snapshot));
    } catch (e) {
      _logger.error('Failed to refresh subscription status: $e');
      return _publishError('Failed to refresh subscription status.');
    }
  }

  @override
  Future<SubscriptionStatus> restorePurchases() async {
    if (!_isConfigured) {
      await initialize();
      if (!_isConfigured) return _currentStatus;
    }

    try {
      final snapshot = await _client.restorePurchases();
      return _publish(_toStatus(snapshot));
    } catch (e) {
      _logger.error('Failed to restore purchases: $e');
      return _publishError('Failed to restore purchases.');
    }
  }

  @override
  Future<List<SubscriptionProduct>> getProducts() async {
    if (!_isConfigured) {
      await initialize();
      if (!_isConfigured) return const [];
    }

    try {
      final products = await _client.getCurrentOfferingProducts();
      final ordered = <SubscriptionProduct>[];
      final byPackage = <String, RevenueCatProductSnapshot>{
        for (final item in products) item.packageId: item,
      };

      for (final packageId in _config.packageIdsInDisplayOrder) {
        final found = byPackage[packageId];
        if (found == null) continue;
        ordered.add(
          SubscriptionProduct(
            packageId: found.packageId,
            productId: found.productId,
            title: found.title,
            priceText: found.priceText,
            description: found.description,
          ),
        );
      }

      // Keep any additional packages after configured ones.
      for (final item in products) {
        if (_config.packageIdsInDisplayOrder.contains(item.packageId)) continue;
        ordered.add(
          SubscriptionProduct(
            packageId: item.packageId,
            productId: item.productId,
            title: item.title,
            priceText: item.priceText,
            description: item.description,
          ),
        );
      }
      return ordered;
    } catch (e) {
      _logger.error('Failed to load products: $e');
      _publishError('Failed to load subscription products.');
      return const [];
    }
  }

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async {
    if (!_isConfigured) {
      await initialize();
      if (!_isConfigured) return _currentStatus;
    }

    // Guard billing availability.
    final canPay = await _canMakePaymentsSafely();
    if (!canPay) {
      return _publishError('Purchases are unavailable on this device.');
    }

    try {
      final snapshot = await _client.purchasePackage(packageId: packageId);
      return _publish(_toStatus(snapshot));
    } catch (e) {
      _logger.error('Failed to purchase package "$packageId": $e');
      return _publishError('Purchase failed. Please try again.');
    }
  }

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async {
    if (!_isConfigured) {
      await initialize();
      if (!_isConfigured) return SubscriptionPaywallResult.notPresented;
    }

    // Guard billing availability.
    final canPay = await _canMakePaymentsSafely();
    if (!canPay) {
      _publishError('Purchases are unavailable on this device.');
      return SubscriptionPaywallResult.notPresented;
    }

    try {
      final result = await _client.presentPaywallIfNeeded(
        entitlementId: _config.entitlementId,
      );

      if (result == SubscriptionPaywallResult.purchased ||
          result == SubscriptionPaywallResult.restored) {
        await refresh();
      }
      return result;
    } catch (e) {
      _logger.error('Failed to present paywall: $e');
      _publishError('Failed to present paywall.');
      return SubscriptionPaywallResult.error;
    }
  }

  @override
  Future<void> presentCustomerCenter() async {
    if (!_isConfigured) {
      await initialize();
      if (!_isConfigured) return;
    }

    try {
      await _client.presentCustomerCenter();
    } catch (e) {
      _logger.error('Failed to present customer center: $e');
      _publishError('Failed to open customer center.');
    }
  }

  @override
  Future<void> close() async {
    await _customerInfoSubscription?.cancel();
    _customerInfoSubscription = null;
    await _client.close();
    await _statusController.close();
  }

  void _ensureCustomerInfoSubscription() {
    if (_customerInfoSubscription != null) return;

    _customerInfoSubscription = _client.customerInfoStream.listen(
      (snapshot) {
        _publish(_toStatus(snapshot));
      },
      onError: (error) {
        _logger.error('Customer info stream error: $error');
        _publishError('Subscription updates are temporarily unavailable.');
      },
    );
  }

  SubscriptionStatus _toStatus(RevenueCatCustomerSnapshot snapshot) {
    final entitlement = _findEntitlement(snapshot);
    final isPro = entitlement?.isActive ?? false;

    return SubscriptionStatus(
      isPro: isPro,
      entitlementId: _config.entitlementId,
      expiresAt: entitlement?.expirationDate,
      lastUpdatedAt: DateTime.now(),
    );
  }

  RevenueCatEntitlementSnapshot? _findEntitlement(
    RevenueCatCustomerSnapshot snapshot,
  ) {
    final configured = snapshot.entitlements[_config.entitlementId];
    if (configured != null) return configured;

    // Backward-compatible fallback while dashboard identifiers stabilize.
    return snapshot.entitlements['pro'] ?? snapshot.entitlements['Flymap Pro'];
  }

  SubscriptionStatus _publish(
    SubscriptionStatus status, {
    bool persist = true,
  }) {
    _currentStatus = status;
    if (persist) {
      unawaited(_statusCache.save(status));
    }
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
    return status;
  }

  SubscriptionStatus _publishError(String message) {
    final status = _currentStatus.copyWith(
      lastUpdatedAt: DateTime.now(),
      error: message,
    );
    return _publish(status, persist: false);
  }

  Future<bool> _canMakePaymentsSafely() async {
    try {
      return await _client.canMakePayments();
    } catch (e) {
      _logger.error('Failed to check billing availability: $e');
      return false;
    }
  }
}

class _NoopSubscriptionStatusCache implements SubscriptionStatusCache {
  const _NoopSubscriptionStatusCache();

  @override
  Future<SubscriptionStatus?> load() async {
    return null;
  }

  @override
  Future<void> save(SubscriptionStatus status) async {}
}
