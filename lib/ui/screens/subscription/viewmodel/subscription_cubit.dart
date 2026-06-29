import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_status.dart';

import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({
    required SubscriptionRepository repository,
    required FlightUnlockRepository flightUnlockRepository,
    required AppAnalytics analytics,
  }) : _repository = repository,
       _flightUnlockRepository = flightUnlockRepository,
       _analytics = analytics,
       super(const SubscriptionState()) {
    _statusSubscription = _repository.statusStream.listen(_onStatusUpdate);
    _unlockBalanceSubscription = _flightUnlockRepository.balanceStream.listen(
      _onUnlockBalanceUpdate,
    );
  }

  final SubscriptionRepository _repository;
  final FlightUnlockRepository _flightUnlockRepository;
  final AppAnalytics _analytics;
  final _logger = const Logger('SubscriptionCubit');

  StreamSubscription<SubscriptionStatus>? _statusSubscription;
  StreamSubscription<int>? _unlockBalanceSubscription;

  Future<void> initialize() async {
    if (state.phase == SubscriptionPhase.loading) return;
    emit(
      state.copyWith(
        phase: SubscriptionPhase.loading,
        isProductsLoading: true,
        clearError: true,
        clearFlightUnlockError: true,
      ),
    );

    try {
      final unusedUnlockCount = await _flightUnlockRepository.initialize();
      _emitUnlockBalance(unusedUnlockCount);
      final status = await _repository.initialize();
      _emitStatus(status, source: 'refresh');
      await loadProducts();
      _preloadFlightUnlockProductIfNeeded(unusedUnlockCount);
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

  Future<void> refresh({String source = 'refresh'}) async {
    emit(state.copyWith(phase: SubscriptionPhase.loading, clearError: true));
    final status = await _repository.refresh();
    _emitStatus(status, source: source);
  }

  Future<void> restorePurchases() async {
    emit(state.copyWith(phase: SubscriptionPhase.loading, clearError: true));
    final status = await _repository.restorePurchases();
    _emitStatus(status, source: 'restore');
    final restoreResult = status.error != null
        ? RestorePurchasesAnalyticsResult.error
        : status.isPro
        ? RestorePurchasesAnalyticsResult.proRestored
        : RestorePurchasesAnalyticsResult.noSubscription;
    unawaited(
      _analytics.log(RestorePurchasesResultEvent(result: restoreResult)),
    );
  }

  Future<void> loadProducts() async {
    emit(state.copyWith(isProductsLoading: true));
    final products = await _repository.getProducts();
    emit(state.copyWith(products: products, isProductsLoading: false));
  }

  Future<FlightUnlockProduct?> loadFlightUnlockProduct({
    bool showUnavailableError = true,
  }) async {
    if (state.isFlightUnlockLoading) return state.flightUnlockProduct;
    emit(
      state.copyWith(
        isFlightUnlockLoading: true,
        clearFlightUnlockError: showUnavailableError,
      ),
    );
    final product = await _flightUnlockRepository.getUnlockProduct();
    final cachedProduct = state.flightUnlockProduct;
    final resolvedProduct = product ?? cachedProduct;
    final shouldShowUnavailableError =
        showUnavailableError && resolvedProduct == null;
    emit(
      state.copyWith(
        flightUnlockProduct: resolvedProduct,
        isFlightUnlockLoading: false,
        flightUnlockErrorMessage: shouldShowUnavailableError
            ? t.subscription.flightUnlockUnavailable
            : null,
        clearFlightUnlockError: !shouldShowUnavailableError,
      ),
    );
    return resolvedProduct;
  }

  Future<FlightUnlockPurchaseResult> purchaseFlightUnlock() async {
    if (state.isFlightUnlockPurchaseLoading) {
      return const FlightUnlockPurchaseResult.cancelled();
    }
    emit(
      state.copyWith(
        isFlightUnlockPurchaseLoading: true,
        clearFlightUnlockError: true,
      ),
    );
    final result = await _flightUnlockRepository.purchaseUnlock();
    emit(
      state.copyWith(
        isFlightUnlockPurchaseLoading: false,
        flightUnlockErrorMessage: switch (result.status) {
          FlightUnlockPurchaseStatus.purchased => null,
          FlightUnlockPurchaseStatus.cancelled =>
            t.subscription.flightUnlockPurchaseCancelled,
          FlightUnlockPurchaseStatus.error =>
            t.subscription.flightUnlockPurchaseFailed,
        },
        clearFlightUnlockError:
            result.status == FlightUnlockPurchaseStatus.purchased,
      ),
    );
    return result;
  }

  void clearFlightUnlockError() {
    if (state.flightUnlockErrorMessage == null ||
        state.flightUnlockErrorMessage!.trim().isEmpty) {
      return;
    }
    emit(state.copyWith(clearFlightUnlockError: true));
  }

  Future<void> purchasePackage(String packageId) async {
    emit(state.copyWith(phase: SubscriptionPhase.loading, clearError: true));
    final status = await _repository.purchasePackage(packageId: packageId);
    _emitStatus(status, source: 'purchase');
  }

  Future<SubscriptionPaywallResult> presentPaywallForCreateFlight() async {
    final source = PaywallSource.wikiLimit;
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

  Future<SubscriptionPaywallResult> presentPaywallFromGeoQuiz() async {
    return _presentPaywallIfNeeded(source: PaywallSource.geoQuizLockedContent);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromOnboarding() async {
    return _presentPaywallIfNeeded(source: PaywallSource.onboarding);
  }

  Future<SubscriptionPaywallResult>
  presentPaywallFromRouteOverviewGate() async {
    return _presentPaywallIfNeeded(source: PaywallSource.routeOverviewGate);
  }

  Future<SubscriptionPaywallResult>
  presentPaywallFromRouteTimelineGate() async {
    return _presentPaywallIfNeeded(source: PaywallSource.routeTimelineGate);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromGeoAwarenessGate() async {
    return _presentPaywallIfNeeded(source: PaywallSource.geoAwarenessGate);
  }

  Future<SubscriptionPaywallResult> presentPaywallFromRealRouteGate() async {
    return _presentPaywallIfNeeded(source: PaywallSource.realRouteGate);
  }

  Future<SubscriptionPaywallResult> presentPaywallForSource({
    required PaywallSource source,
  }) async {
    return _presentPaywallIfNeeded(source: source);
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
    unawaited(
      _analytics.log(
        PaywallPresentedEvent(
          source: source,
          isProUser: state.isPro,
          hasProducts: state.products.isNotEmpty,
        ),
      ),
    );
    final result = await _repository.presentPaywallIfNeeded();
    unawaited(
      _analytics.log(PaywallResultEvent(source: source, result: result)),
    );
    if (result == SubscriptionPaywallResult.purchased ||
        result == SubscriptionPaywallResult.restored) {
      await refresh(
        source: result == SubscriptionPaywallResult.purchased
            ? 'purchase'
            : 'restore',
      );
    }
    return result;
  }

  Future<void> presentCustomerCenter() async {
    await _repository.presentCustomerCenter();
    await refresh();
  }

  void _onStatusUpdate(SubscriptionStatus status) {
    _emitStatus(status, source: 'customer_info_stream');
  }

  void _onUnlockBalanceUpdate(int unusedUnlockCount) {
    _emitUnlockBalance(unusedUnlockCount);
  }

  void _emitStatus(SubscriptionStatus status, {required String source}) {
    final previousStatus = state.status;
    unawaited(_analytics.setSubscriptionContext(isPro: status.isPro));
    if (previousStatus != null && previousStatus.isPro != status.isPro) {
      unawaited(
        _analytics.log(
          SubscriptionStatusChangedEvent(
            fromStatus: _subscriptionStatusName(previousStatus),
            toStatus: _subscriptionStatusName(status),
            source: source,
          ),
        ),
      );
    }
    emit(
      state.copyWith(
        phase: status.isPro ? SubscriptionPhase.pro : SubscriptionPhase.free,
        status: status,
        errorMessage: status.error,
      ),
    );
  }

  String _subscriptionStatusName(SubscriptionStatus status) {
    return status.isPro ? 'pro' : 'free';
  }

  void _emitUnlockBalance(int unusedUnlockCount) {
    emit(state.copyWith(unusedFlightUnlockCount: unusedUnlockCount));
  }

  void _preloadFlightUnlockProductIfNeeded(int unusedUnlockCount) {
    if (unusedUnlockCount > 0 ||
        state.flightUnlockProduct != null ||
        state.isFlightUnlockLoading) {
      return;
    }
    unawaited(loadFlightUnlockProduct(showUnavailableError: false));
  }

  @override
  Future<void> close() async {
    await _statusSubscription?.cancel();
    await _unlockBalanceSubscription?.cancel();
    return super.close();
  }
}
