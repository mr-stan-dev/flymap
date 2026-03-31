import 'package:equatable/equatable.dart';

class SubscriptionStatus extends Equatable {
  const SubscriptionStatus({
    required this.isPro,
    required this.entitlementId,
    required this.lastUpdatedAt,
    this.expiresAt,
    this.error,
  });

  final bool isPro;
  final String entitlementId;
  final DateTime? expiresAt;
  final DateTime lastUpdatedAt;
  final String? error;

  SubscriptionStatus copyWith({
    bool? isPro,
    String? entitlementId,
    DateTime? expiresAt,
    DateTime? lastUpdatedAt,
    String? error,
    bool clearError = false,
  }) {
    return SubscriptionStatus(
      isPro: isPro ?? this.isPro,
      entitlementId: entitlementId ?? this.entitlementId,
      expiresAt: expiresAt ?? this.expiresAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    isPro,
    entitlementId,
    expiresAt,
    lastUpdatedAt,
    error,
  ];
}
