import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';

class RoutePremiumGateInteractions {
  const RoutePremiumGateInteractions._();

  static Future<void> onGateTap({
    required BuildContext context,
    required PaywallSource source,
    required bool useOfflineInfoSheet,
    Future<void> Function()? onActivated,
  }) async {
    final subscriptionCubit = context.read<SubscriptionCubit>();
    if (subscriptionCubit.state.isPro) return;

    if (useOfflineInfoSheet) {
      final hasInternet = await const ConnectivityChecker()
          .hasInternetConnectivity();
      if (!hasInternet) {
        if (!context.mounted) return;
        await showOfflineInfoSheet(context);
        return;
      }
    }

    final result = await subscriptionCubit.presentPaywallForSource(
      source: source,
    );
    if (!context.mounted) return;
    if ((result == SubscriptionPaywallResult.purchased ||
            result == SubscriptionPaywallResult.restored) &&
        onActivated != null) {
      await onActivated();
      if (!context.mounted) return;
    }
    _showPaywallResultSnackbar(context, result);
  }

  /// Shown when a gate is tapped with no connectivity — the paywall/unlock
  /// purchase needs the network, so explain instead of failing.
  static Future<void> showOfflineInfoSheet(BuildContext context) async {
    final t = context.t;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.flight.route.premiumOfflineTitle,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                t.flight.route.premiumOfflineBody,
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(t.common.ok),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static void _showPaywallResultSnackbar(
    BuildContext context,
    SubscriptionPaywallResult result,
  ) {
    final t = context.t;
    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case SubscriptionPaywallResult.purchased:
      case SubscriptionPaywallResult.restored:
        messenger.showSnackBar(
          SnackBar(content: Text(t.settings.flymapProActivated)),
        );
        return;
      case SubscriptionPaywallResult.cancelled:
        messenger.showSnackBar(
          SnackBar(content: Text(t.settings.upgradeCancelled)),
        );
        return;
      case SubscriptionPaywallResult.notPresented:
        messenger.showSnackBar(SnackBar(content: Text(t.settings.noPaywall)));
        return;
      case SubscriptionPaywallResult.error:
        messenger.showSnackBar(
          SnackBar(content: Text(t.settings.failedOpenPaywall)),
        );
        return;
    }
  }
}
