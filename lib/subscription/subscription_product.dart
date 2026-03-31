import 'package:equatable/equatable.dart';

class SubscriptionProduct extends Equatable {
  const SubscriptionProduct({
    required this.packageId,
    required this.productId,
    required this.title,
    required this.priceText,
    this.description = '',
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
