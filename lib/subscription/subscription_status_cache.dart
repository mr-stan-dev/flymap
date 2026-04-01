import 'dart:convert';

import 'package:flymap/logger.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SubscriptionStatusCache {
  Future<SubscriptionStatus?> load();

  Future<void> save(SubscriptionStatus status);
}

class SharedPrefsSubscriptionStatusCache implements SubscriptionStatusCache {
  SharedPrefsSubscriptionStatusCache();

  static const _cacheKey = 'subscription.status.v1';
  final _logger = const Logger('SubscriptionStatusCache');

  @override
  Future<SubscriptionStatus?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final entitlementId = (decoded['entitlementId'] as String? ?? '').trim();
      final lastUpdatedAtRaw = decoded['lastUpdatedAt'] as String?;
      final lastUpdatedAt = DateTime.tryParse(lastUpdatedAtRaw ?? '');
      if (entitlementId.isEmpty || lastUpdatedAt == null) return null;

      final expiresAtRaw = decoded['expiresAt'] as String?;
      final expiresAt = (expiresAtRaw == null || expiresAtRaw.trim().isEmpty)
          ? null
          : DateTime.tryParse(expiresAtRaw);

      return SubscriptionStatus(
        isPro: decoded['isPro'] == true,
        entitlementId: entitlementId,
        expiresAt: expiresAt,
        lastUpdatedAt: lastUpdatedAt,
      );
    } catch (e) {
      _logger.error('Failed to read cached subscription status: $e');
      return null;
    }
  }

  @override
  Future<void> save(SubscriptionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode({
        'isPro': status.isPro,
        'entitlementId': status.entitlementId,
        'expiresAt': status.expiresAt?.toUtc().toIso8601String(),
        'lastUpdatedAt': status.lastUpdatedAt.toUtc().toIso8601String(),
      });
      await prefs.setString(_cacheKey, payload);
    } catch (e) {
      _logger.error('Failed to persist subscription status cache: $e');
    }
  }
}
