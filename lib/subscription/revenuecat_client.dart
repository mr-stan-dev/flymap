import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'subscription_paywall_result.dart';

class RevenueCatEntitlementSnapshot extends Equatable {
  const RevenueCatEntitlementSnapshot({
    required this.isActive,
    this.expirationDate,
  });

  final bool isActive;
  final DateTime? expirationDate;

  @override
  List<Object?> get props => [isActive, expirationDate];
}

class RevenueCatCustomerSnapshot extends Equatable {
  const RevenueCatCustomerSnapshot({required this.entitlements});

  final Map<String, RevenueCatEntitlementSnapshot> entitlements;

  @override
  List<Object?> get props => [entitlements];
}

class RevenueCatProductSnapshot extends Equatable {
  const RevenueCatProductSnapshot({
    required this.packageId,
    required this.productId,
    required this.title,
    required this.priceText,
    required this.description,
  });

  final String packageId;
  final String productId;
  final String title;
  final String priceText;
  final String description;

  @override
  List<Object?> get props => [
    packageId,
    productId,
    title,
    priceText,
    description,
  ];
}

abstract class RevenueCatClient {
  Stream<RevenueCatCustomerSnapshot> get customerInfoStream;

  Future<void> configure({required String apiKey});

  Future<RevenueCatCustomerSnapshot> getCustomerInfo();

  Future<RevenueCatCustomerSnapshot> restorePurchases();

  Future<List<RevenueCatProductSnapshot>> getCurrentOfferingProducts();

  Future<RevenueCatCustomerSnapshot> purchasePackage({
    required String packageId,
  });

  Future<SubscriptionPaywallResult> presentPaywallIfNeeded({
    required String entitlementId,
  });

  Future<void> presentCustomerCenter();

  Future<void> close();
}

class PurchasesRevenueCatClient implements RevenueCatClient {
  PurchasesRevenueCatClient();

  final StreamController<RevenueCatCustomerSnapshot> _controller =
      StreamController<RevenueCatCustomerSnapshot>.broadcast();

  CustomerInfoUpdateListener? _listener;
  bool _isConfigured = false;

  @override
  Stream<RevenueCatCustomerSnapshot> get customerInfoStream =>
      _controller.stream;

  @override
  Future<void> configure({required String apiKey}) async {
    if (!_isConfigured) {
      final config = PurchasesConfiguration(apiKey);
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(config);
      _ensureListener();
      _isConfigured = true;
      return;
    }

    // Keep behavior deterministic when initialize is called repeatedly.
    _ensureListener();
  }

  @override
  Future<RevenueCatCustomerSnapshot> getCustomerInfo() async {
    final info = await Purchases.getCustomerInfo();
    return _mapCustomerInfo(info);
  }

  @override
  Future<RevenueCatCustomerSnapshot> restorePurchases() async {
    final info = await Purchases.restorePurchases();
    return _mapCustomerInfo(info);
  }

  @override
  Future<List<RevenueCatProductSnapshot>> getCurrentOfferingProducts() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return const [];

    return current.availablePackages.map((package) {
      final product = package.storeProduct;
      return RevenueCatProductSnapshot(
        packageId: package.identifier,
        productId: product.identifier,
        title: product.title,
        priceText: product.priceString,
        description: product.description,
      );
    }).toList();
  }

  @override
  Future<RevenueCatCustomerSnapshot> purchasePackage({
    required String packageId,
  }) async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      throw StateError('No current RevenueCat offering is available.');
    }

    final package = current.availablePackages.where((package) {
      return package.identifier == packageId;
    }).firstOrNull;
    if (package == null) {
      throw StateError(
        'Package "$packageId" was not found in current offering.',
      );
    }

    final result = await Purchases.purchase(PurchaseParams.package(package));
    return _mapCustomerInfo(result.customerInfo);
  }

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded({
    required String entitlementId,
  }) async {
    final result = await RevenueCatUI.presentPaywallIfNeeded(entitlementId);
    switch (result) {
      case PaywallResult.purchased:
        return SubscriptionPaywallResult.purchased;
      case PaywallResult.restored:
        return SubscriptionPaywallResult.restored;
      case PaywallResult.cancelled:
        return SubscriptionPaywallResult.cancelled;
      case PaywallResult.notPresented:
        return SubscriptionPaywallResult.notPresented;
      case PaywallResult.error:
        return SubscriptionPaywallResult.error;
    }
  }

  @override
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }

  @override
  Future<void> close() async {
    final listener = _listener;
    if (listener != null) {
      Purchases.removeCustomerInfoUpdateListener(listener);
      _listener = null;
    }
    await _controller.close();
  }

  void _ensureListener() {
    if (_listener != null) return;

    _listener = (customerInfo) {
      if (_controller.isClosed) return;
      _controller.add(_mapCustomerInfo(customerInfo));
    };
    Purchases.addCustomerInfoUpdateListener(_listener!);
  }

  RevenueCatCustomerSnapshot _mapCustomerInfo(CustomerInfo info) {
    final entitlements = <String, RevenueCatEntitlementSnapshot>{};
    for (final entry in info.entitlements.all.entries) {
      entitlements[entry.key] = RevenueCatEntitlementSnapshot(
        isActive: entry.value.isActive,
        expirationDate: _parseDate(entry.value.expirationDate),
      );
    }

    return RevenueCatCustomerSnapshot(entitlements: entitlements);
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
