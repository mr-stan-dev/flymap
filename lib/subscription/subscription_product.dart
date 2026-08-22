import 'package:equatable/equatable.dart';

class SubscriptionProduct extends Equatable {
  const SubscriptionProduct({
    required this.packageId,
    required this.productId,
    required this.title,
    required this.priceText,
    this.description = '',
    this.productPlanId,
    this.subscriptionPeriod,
  });

  final String packageId;
  final String productId;
  final String title;
  final String priceText;
  final String description;
  final String? productPlanId;

  /// ISO 8601 billing period reported by the store, for example P1W or P1M.
  final String? subscriptionPeriod;

  @override
  List<Object?> get props => [
    packageId,
    productId,
    title,
    priceText,
    description,
    productPlanId,
    subscriptionPeriod,
  ];
}
