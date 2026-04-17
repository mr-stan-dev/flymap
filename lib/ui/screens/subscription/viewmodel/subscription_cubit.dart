import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_status.dart';

import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required SubscriptionRepository repository,
    required AppAnalytics analytics,
  }) : _repository = repository,
       _analytics = analytics,
       super(const SubscriptionState()) {
    _statusSubscription = _repository.statusStream.listen(_onStatusUpdate);
  }

  final SubscriptionRepository _repository;
  final AppAnalytics _analytics;
  final _logger = const Logger('SubscriptionCubit');

  StreamSubscription<SubscriptionStatus>? _statusSubscription;

  Future<void> initialize() async {
    if (state.phase == SubscriptionPhase.loading) return;
    emit(
      state.copyWith(
        phase: SubscriptionPhase.loading,
        isProductsLoading: true,
        clearError: true,
      ),
    );

    try {
      final status = await _repository.initialize();
      _emitStatus(status);
      await loadProducts();
    } catch (e) {
      _logger.error('Initialize failed: $e');
      emit(
        state.copyWith(
          phase: SubscriptionPhase.free,
          errorMessage: t.subscription.serviceUnavailable,
          isProductsLoading: false,
        ),
      );
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(phase: SubscriptionPhase.loading, clearError: true));
    final status = await _repository.refresh();
    _emitStatus(status);
  }

  Future<void> restorePurchases() async {
    emit(state.copyWith(phase: SubscriptionPhase.loading, clearError: true));
    final status = await _repository.restorePurchases();
    _emitStatus(status);
  }

  Future<void> loadProducts() async {
    emit(state.copyWith(isProductsLoading: true));
    final products = await _repository.getProducts();
    emit(state.copyWith(products: products, isProductsLoading: false));
  }

  Future<void> purchasePackage(String packageId) async {
    emit(state.copyWith(phase: SubscriptionPhase.loading, clearError: true));
    final status = await _repository.purchasePackage(packageId: packageId);
    _emitStatus(status);
  }

  Future<SubscriptionPaywallResult> presentPaywallForCreateFlight({
    required bool shouldUpgradeForArticles,
    required bool shouldUpgradeForMapConfig,
  }) async {
    final source = shouldUpgradeForArticles && shouldUpgradeForMapConfig
        ? PaywallSource.wikiAndMapPro
        : shouldUpgradeForArticles
        ? PaywallSource.wikiLimit
        : PaywallSource.mapPro;
    return _presentPaywallIfNeeded(source: source);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromSettings() async {
    return _presentPaywallIfNeeded(source: PaywallSource.settingsBanner);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromOverviewPoi() async {
    return _presentPaywallIfNeeded(source: PaywallSource.poiSection);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromLearn() async {
    return _presentPaywallIfNeeded(source: PaywallSource.learnLockedContent);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromOnboarding() async {
    return _presentPaywallIfNeeded(source: PaywallSource.onboarding);
  }

  Future<SubscriptionPaywallResult>
  presentPaywallFromSubscriptionManagement() async {
    return _presentPaywallIfNeeded(
      source: PaywallSource.subscriptionManagement,
    );
  }

  Future<SubscriptionPaywallResult> _presentPaywallIfNeeded({
    required PaywallSource source,
  }) async {
    final result = await _repository.presentPaywallIfNeeded();
    unawaited(
      _analytics.log(PaywallResultEvent(source: source, result: result)),
    );
    if (result == SubscriptionPaywallResult.purchased ||
        result == SubscriptionPaywallResult.restored) {
      await refresh();
    }
    return result;
  }

  Future<void> presentCustomerCenter() async {
    await _repository.presentCustomerCenter();
    await refresh();
  }

  void _onStatusUpdate(SubscriptionStatus status) {
    _emitStatus(status);
  }

  void _emitStatus(SubscriptionStatus status) {
    unawaited(_analytics.setSubscriptionContext(isPro: status.isPro));
    emit(
      state.copyWith(
        phase: status.isPro ? SubscriptionPhase.pro : SubscriptionPhase.free,
        status: status,
        errorMessage: status.error,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _statusSubscription?.cancel();
    return super.close();
  }
}
