import 'dart:async';

import 'package:flymap/analytics/app_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_unlock_bottom_sheet.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

Future<void> showFlightUnlockGateSheet({
  required BuildContext context,
  required SubscriptionCubit subscriptionCubit,
  required PaywallSource source,
  required Future<SubscriptionPaywallResult> Function() presentProPaywall,
  Future<void> Function()? onUnlockActivated,
  Future<void> Function()? onProActivated,
  String? routePreview,
  String? creationAttemptId,
}) async {
  final analytics = GetIt.I.get<AppAnalytics>();
  final gateAttemptId = const Uuid().v4();
  var sheetClosedByAction = false;

  if (subscriptionCubit.state.unusedFlightUnlockCount <= 0 &&
      subscriptionCubit.state.flightUnlockProduct == null &&
      !subscriptionCubit.state.isFlightUnlockLoading) {
    unawaited(
      subscriptionCubit.loadFlightUnlockProduct(showUnavailableError: false),
    );
  }
  unawaited(
    analytics.log(
      FlightUnlockSheetOpenedEvent(
        source: source,
        unusedUnlockCount: subscriptionCubit.state.unusedFlightUnlockCount,
        hasCachedProduct: subscriptionCubit.state.flightUnlockProduct != null,
        gateAttemptId: gateAttemptId,
        creationAttemptId: creationAttemptId,
      ),
    ),
  );

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return FlightUnlockBottomSheet(
        routePreview: routePreview,
        onUnlockFlight: (innerContext) async {
          final hasExistingUnlock =
              subscriptionCubit.state.unusedFlightUnlockCount > 0;
          unawaited(
            analytics.log(
              FlightUnlockActionEvent(
                source: source,
                action: hasExistingUnlock
                    ? FlightUnlockActionType.useExisting
                    : FlightUnlockActionType.buyUnlock,
                unusedUnlockCount:
                    subscriptionCubit.state.unusedFlightUnlockCount,
                gateAttemptId: gateAttemptId,
                creationAttemptId: creationAttemptId,
              ),
            ),
          );
          if (!hasExistingUnlock) {
            final purchaseResult = await subscriptionCubit
                .purchaseFlightUnlock();
            unawaited(
              analytics.log(
                FlightUnlockPurchaseResultEvent(
                  source: source,
                  result: purchaseResult.status,
                  productId: purchaseResult.productId,
                  balanceAfter: subscriptionCubit.state.unusedFlightUnlockCount,
                  gateAttemptId: gateAttemptId,
                  creationAttemptId: creationAttemptId,
                ),
              ),
            );
            if (!innerContext.mounted ||
                !purchaseResult.isPurchased ||
                purchaseResult.status != FlightUnlockPurchaseStatus.purchased) {
              return;
            }
          }

          if (!innerContext.mounted) return;
          sheetClosedByAction = true;
          Navigator.of(innerContext).pop();
          if (onUnlockActivated != null) {
            await onUnlockActivated();
          }
        },
        onViewProPlans: (innerContext) async {
          unawaited(
            analytics.log(
              FlightUnlockActionEvent(
                source: source,
                action: FlightUnlockActionType.viewProPlans,
                unusedUnlockCount:
                    subscriptionCubit.state.unusedFlightUnlockCount,
                gateAttemptId: gateAttemptId,
                creationAttemptId: creationAttemptId,
              ),
            ),
          );
          sheetClosedByAction = true;
          Navigator.of(innerContext).pop();
          final result = await presentProPaywall();
          if (!context.mounted) return;

          switch (result) {
            case SubscriptionPaywallResult.purchased:
            case SubscriptionPaywallResult.restored:
              if (onProActivated != null) {
                await onProActivated();
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.t.settings.flymapProActivated)),
              );
              return;
            case SubscriptionPaywallResult.cancelled:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.t.createFlight.paywall.upgradeCancelled,
                  ),
                ),
              );
              return;
            case SubscriptionPaywallResult.notPresented:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.t.createFlight.paywall.noPaywall),
                ),
              );
              return;
            case SubscriptionPaywallResult.error:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.t.createFlight.paywall.failedOpenPaywall,
                  ),
                ),
              );
              return;
          }
        },
      );
    },
  );

  if (!sheetClosedByAction) {
    unawaited(
      analytics.log(
        FlightUnlockActionEvent(
          source: source,
          action: FlightUnlockActionType.dismissed,
          unusedUnlockCount: subscriptionCubit.state.unusedFlightUnlockCount,
          gateAttemptId: gateAttemptId,
          creationAttemptId: creationAttemptId,
        ),
      ),
    );
  }

  subscriptionCubit.clearFlightUnlockError();
}
