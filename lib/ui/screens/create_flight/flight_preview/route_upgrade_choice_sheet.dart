import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/settings/widgets/safe_bottom_sheet.dart';
import 'package:get_it/get_it.dart';

/// After a mid-preview upgrade (subscription or single-flight unlock) on an
/// approximate route, offers to rebuild the flight from the real flight
/// track. Nothing is fetched automatically: the primary action only takes
/// the user to the flight-number screen, where the search is user-triggered.
///
/// No-op when the current route is already a real track or the user entered
/// via a flight number (nothing better to offer).
Future<void> maybeShowRouteUpgradeChoiceSheet({
  required BuildContext context,
  required FlightPreviewCubit cubit,
  required PaywallSource source,
}) async {
  final route = cubit.state.flightRoute;
  final hasFlightNumber = (cubit.flightNumber ?? '').trim().isNotEmpty;
  if (route == null || route.isHistoricalTrack || hasFlightNumber) return;

  final analytics = GetIt.I.get<AppAnalytics>();
  unawaited(
    analytics.log(
      RealRouteChoiceEvent(
        source: source,
        action: RealRouteChoiceAction.shown,
        creationAttemptId: cubit.creationAttemptId,
      ),
    ),
  );

  RealRouteChoiceAction? selectedAction;
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      final strings = sheetContext.t.createFlight.realRouteChoice;
      final theme = Theme.of(sheetContext);
      return SafeBottomSheet(
        padding: const EdgeInsets.fromLTRB(
          DsSpacing.lg,
          DsSpacing.xs,
          DsSpacing.lg,
          DsSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: DsSpacing.sm),
            Text(
              strings.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: DsSpacing.lg),
            PrimaryButton(
              label: strings.ctaEnterFlightNumber,
              onPressed: () {
                selectedAction = RealRouteChoiceAction.enterFlightNumber;
                Navigator.of(sheetContext).pop();
              },
            ),
            const SizedBox(height: DsSpacing.sm),
            TertiaryButton(
              label: strings.ctaKeepRoute,
              onPressed: () {
                selectedAction = RealRouteChoiceAction.keepRoute;
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      );
    },
  );

  unawaited(
    analytics.log(
      RealRouteChoiceEvent(
        source: source,
        action: selectedAction ?? RealRouteChoiceAction.dismissed,
        creationAttemptId: cubit.creationAttemptId,
      ),
    ),
  );

  if (selectedAction != RealRouteChoiceAction.enterFlightNumber ||
      !context.mounted) {
    return;
  }
  AppRouter.goToFlightNumberSelector(
    context,
    hasPendingFlightUnlock: cubit.state.hasPendingFlightUnlock,
  );
}
