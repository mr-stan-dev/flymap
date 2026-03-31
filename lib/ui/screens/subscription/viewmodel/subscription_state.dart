import 'package:equatable/equatable.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';

enum SubscriptionPhase { unknown, loading, free, pro }

class SubscriptionState extends Equatable {
  const SubscriptionState({
    this.phase = SubscriptionPhase.unknown,
    this.status,
    this.errorMessage,
    this.products = const <SubscriptionProduct>[],
    this.isProductsLoading = false,
  });

  final SubscriptionPhase phase;
  final SubscriptionStatus? status;
  final String? errorMessage;
  final List<SubscriptionProduct> products;
  final bool isProductsLoading;

  bool get isPro => phase == SubscriptionPhase.pro;

  bool get isLoading =>
      phase == SubscriptionPhase.loading || phase == SubscriptionPhase.unknown;

  DateTime? get lastUpdatedAt => status?.lastUpdatedAt;

  SubscriptionState copyWith({
    SubscriptionPhase? phase,
    SubscriptionStatus? status,
    String? errorMessage,
    List<SubscriptionProduct>? products,
    bool? isProductsLoading,
    bool clearError = false,
  }) {
    return SubscriptionState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      products: products ?? this.products,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    status,
    errorMessage,
    products,
    isProductsLoading,
  ];
}
