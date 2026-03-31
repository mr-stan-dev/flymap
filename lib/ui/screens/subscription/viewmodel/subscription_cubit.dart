import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_status.dart';

import 'subscription_state.dart';

class SubscriptionCubit extends Cubit<SubscriptionState> {
  SubscriptionCubit({required SubscriptionRepository repository})
    : _repository = repository,
      super(const SubscriptionState()) {
    _statusSubscription = _repository.statusStream.listen(_onStatusUpdate);
  }

  final SubscriptionRepository _repository;
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
          errorMessage: 'Subscription service is temporarily unavailable.',
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

  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async {
    final result = await _repository.presentPaywallIfNeeded();
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
