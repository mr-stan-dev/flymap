import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/policy/route_region_premium_gate_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/common/route/route_places_by_type.dart';
import 'package:flymap/ui/screens/common/route/route_regions_by_type.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_unlock_gate_sheet.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/route_upgrade_choice_sheet.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/region_info_screen.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_region_type_mapper.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_widget.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class RouteSummaryScreen extends StatelessWidget {
  const RouteSummaryScreen({
    required this.route,
    required this.blockMinutes,
    required this.cruiseSpeedKmh,
    required this.onContinue,
    super.key,
  });

  final FlightRoute route;
  final int blockMinutes;
  final int cruiseSpeedKmh;
  final VoidCallback onContinue;
  static const _typeMapper = RouteTimelineRegionTypeMapper();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final previewState = context.watch<FlightPreviewCubit>().state;
    final liveRegions = previewState.routeRegions;
    final livePois = previewState.flightInfo.poi;
    final isProSubscriber = context.select(
      (SubscriptionCubit cubit) => cubit.state.isPro,
    );
    final isProUser = isProSubscriber || previewState.hasPendingFlightUnlock;
    final orderedRegions = RouteRegionPremiumGatePolicy.orderByDistance(
      liveRegions,
    );
    final gateDecision = RouteRegionPremiumGatePolicy.evaluate(
      orderedRegions: orderedRegions,
      isProUser: isProUser,
    );
    final flightPreviewCubit = context.read<FlightPreviewCubit>();
    final subscriptionCubit = context.read<SubscriptionCubit>();
    final distance = UnitFormatUtils.formatDistanceApprox(
      route.displayDistanceKm.toDouble(),
      context.distanceUnit,
    );
    final duration =
        DurationFormatUtils.formatApprox(context, blockMinutes) ??
        '0 ${t.createFlight.overview.timeline.minuteUnit}';
    final routeTitle =
        '${route.departure.displayCode} → ${route.arrival.displayCode}';
    final routeSubtitle =
        '${RouteUtils.cityLabel(route.departure.city)} → ${RouteUtils.cityLabel(route.arrival.city)}';
    final routePreview =
        '${route.departure.nameShort} → ${route.arrival.nameShort}';

    return Scaffold(
      appBar: AppBar(
        title: Text(t.createFlight.overview.routeSummaryTitle),
        actions: [
          if (isProSubscriber)
            ProAppBarInfoButton(
              title: t.createFlight.proAccess.subscriber,
              message: t.createFlight.proAccess.subscriberBody,
              tooltip: t.createFlight.proAccess.tooltip,
            )
          else if (previewState.hasPendingFlightUnlock)
            ProAppBarInfoButton(
              title: t.createFlight.proAccess.unlockedFlight,
              message: t.createFlight.proAccess.unlockedFlightBody,
              tooltip: t.createFlight.proAccess.tooltip,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routeSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.route_rounded,
                        label:
                            '${t.createFlight.overview.routeSummaryDistanceLabel}: $distance',
                      ),
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label:
                            '${t.createFlight.overview.routeSummaryDurationLabel}: $duration',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (gateDecision.freeRegions.isNotEmpty ||
                gateDecision.premiumRegions.isNotEmpty) ...[
              RouteRegionsByTypeSection(
                regions: gateDecision.freeRegions,
                hiddenRegionsCount: gateDecision.premiumRegions.length,
                onOpenRegion: (region) => _openRegionInfo(context, region),
                onPremiumGateTap: gateDecision.isGated
                    ? () => _showTimelineGateSheet(
                        context: context,
                        subscriptionCubit: subscriptionCubit,
                        flightPreviewCubit: flightPreviewCubit,
                        routePreview: routePreview,
                      )
                    : null,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              t.createFlight.overview.routeSummaryTimelineTitle,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            RouteTimelineWidget(
              route: route,
              regions: liveRegions,
              isProUser: isProUser,
              cruiseSpeedKmh: cruiseSpeedKmh,
              blockMinutes: blockMinutes,
              onPremiumGateTap: () => _showTimelineGateSheet(
                context: context,
                subscriptionCubit: subscriptionCubit,
                flightPreviewCubit: flightPreviewCubit,
                routePreview: routePreview,
              ),
              onOpenRegion: (region) => _openRegionInfo(context, region),
            ),
            const SizedBox(height: 12),
            RoutePlacesByTypeSection(places: livePois),
            const SizedBox(height: 16),
            PrimaryButton(
              label: t.common.kContinue,
              onPressed: () {
                Navigator.of(context).pop();
                onContinue();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimelineGateSheet({
    required BuildContext context,
    required SubscriptionCubit subscriptionCubit,
    required FlightPreviewCubit flightPreviewCubit,
    required String? routePreview,
  }) async {
    await showFlightUnlockGateSheet(
      context: context,
      subscriptionCubit: subscriptionCubit,
      source: PaywallSource.routeTimelineGate,
      onUnlockActivated: () async {
        await flightPreviewCubit.enablePendingFlightUnlock();
        if (context.mounted) {
          await maybeShowRouteUpgradeChoiceSheet(
            context: context,
            cubit: flightPreviewCubit,
            source: PaywallSource.routeTimelineGate,
          );
        }
      },
      onProActivated: () async {
        await flightPreviewCubit.refreshPoisForPro();
        if (context.mounted) {
          await maybeShowRouteUpgradeChoiceSheet(
            context: context,
            cubit: flightPreviewCubit,
            source: PaywallSource.routeTimelineGate,
          );
        }
      },
      routePreview: routePreview,
      presentProPaywall: subscriptionCubit.presentPaywallFromRouteTimelineGate,
    );
  }

  Future<void> _openRegionInfo(BuildContext context, RouteRegion region) async {
    final typeLabel = _typeMapper.mapLabel(context, region.regionType);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegionInfoScreen(region: region, typeLabel: typeLabel),
      ),
    );
  }

}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
