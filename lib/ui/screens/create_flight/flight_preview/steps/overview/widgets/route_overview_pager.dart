import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/route_overview_page_entry.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/region_info_screen.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/widgets/overview_airport_card.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/widgets/overview_premium_gate_card.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/widgets/overview_region_card.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/widgets/overview_summary_card.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/widgets/overview_title_card.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_region_type_mapper.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class RouteOverviewPager extends StatefulWidget {
  const RouteOverviewPager({
    required this.entries,
    required this.route,
    required this.blockMinutes,
    required this.totalRegionCount,
    required this.onRouteSummaryRequested,
    this.initialPage = 0,
    required this.onPageChanged,
    required this.onPremiumGateTap,
    required this.onContinueFromOverview,
    super.key,
  });

  final List<RouteOverviewPageEntry> entries;
  final FlightRoute route;
  final int blockMinutes;
  final int totalRegionCount;
  final VoidCallback onRouteSummaryRequested;
  final int initialPage;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPremiumGateTap;
  final ValueChanged<bool> onContinueFromOverview;

  @override
  State<RouteOverviewPager> createState() => _RouteOverviewPagerState();
}

class _RouteOverviewPagerState extends State<RouteOverviewPager> {
  late final PageController _controller;
  static const _typeMapper = RouteTimelineRegionTypeMapper();

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.88,
      initialPage: widget.initialPage,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolved here, not in itemBuilder: provider forbids select/watch inside
    // a sliver list's item build (it would rebuild the whole list anyway).
    final distanceUnit = context.distanceUnit;
    return PageView.builder(
      controller: _controller,
      padEnds: false,
      itemCount: widget.entries.length,
      onPageChanged: widget.onPageChanged,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        return Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 16 : 6,
            right: index == widget.entries.length - 1 ? 16 : 6,
            top: 4,
            bottom: 8,
          ),
          child: _buildCard(context, entry, distanceUnit),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    RouteOverviewPageEntry entry,
    DistanceUnit distanceUnit,
  ) {
    final t = context.t;
    switch (entry.kind) {
      case RouteOverviewPageKind.summary:
        final route = widget.route;
        // Approximate style ("~1850 km" / "~3h 10m") matching the home card,
        // including the user's distance unit.
        final distance = UnitFormatUtils.formatDistanceApprox(
          route.displayDistanceKm.toDouble(),
          distanceUnit,
        );
        final duration =
            DurationFormatUtils.formatApprox(context, widget.blockMinutes) ??
            _formatMinutesCompact(context, widget.blockMinutes);
        return OverviewTitleCard(
          routeCodeLine:
              '${route.departure.displayCode} → ${route.arrival.displayCode}',
          routeCitiesLine:
              '${RouteUtils.cityLabel(route.departure.city)} → ${RouteUtils.cityLabel(route.arrival.city)}',
          distanceLabel: t.createFlight.overview.routeSummaryDistanceLabel,
          distanceValue: distance,
          durationLabel: t.createFlight.overview.routeSummaryDurationLabel,
          durationValue: duration,
          reviewRouteLabel: t.createFlight.overview.startReview,
          onReviewRoute: _animateToNextCard,
          skipReviewLabel: t.createFlight.overview.skipReview,
          onSkipReview: () => widget.onContinueFromOverview(true),
        );
      case RouteOverviewPageKind.departure:
        final airport = entry.airport!;
        return OverviewAirportCard(
          title: airport.name,
          subtitle:
              '${t.flight.info.departure} • ${airport.displayCode} • ${RouteUtils.cityLabel(airport.city)}',
          description: t.createFlight.overview.airportCard.departureDescription(
            airport: airport.name,
          ),
          countryCode: airport.countryCode,
        );
      case RouteOverviewPageKind.arrival:
        final airport = entry.airport!;
        return OverviewAirportCard(
          title: airport.name,
          subtitle:
              '${t.flight.info.arrival} • ${airport.displayCode} • ${RouteUtils.cityLabel(airport.city)}',
          description: t.createFlight.overview.airportCard.arrivalDescription(
            airport: airport.name,
          ),
          countryCode: airport.countryCode,
        );
      case RouteOverviewPageKind.regionGroup:
        final primaryRegion = entry.regionGroup?.topRegion;
        if (primaryRegion == null) {
          return const SizedBox.shrink();
        }
        final typeLabel = _typeMapper.mapLabel(
          context,
          primaryRegion.regionType,
        );
        return OverviewRegionCard(
          title: primaryRegion.name,
          subtitle: typeLabel,
          description: primaryRegion.description?.trim().isNotEmpty == true
              ? primaryRegion.description!.trim()
              : t.createFlight.overview.regionInfo.descriptionUnavailable,
          readMoreLabel: t.common.readMore,
          onReadMore: () => _openRegionInfo(
            context,
            region: primaryRegion,
            typeLabel: typeLabel,
          ),
          regionType: primaryRegion.regionType,
        );
      case RouteOverviewPageKind.premiumGate:
        return OverviewPremiumGateCard(
          title: t.createFlight.overview.premiumGateTitle,
          description: t.createFlight.overview.premiumGateBodyWithCount(
            count: widget.totalRegionCount,
          ),
          ctaLabel: t.createFlight.overview.premiumGateCta,
          onTap: widget.onPremiumGateTap,
        );
      case RouteOverviewPageKind.summaryEnd:
        final route = widget.route;
        final regionCount = widget.totalRegionCount;
        return OverviewSummaryCard(
          title: t.createFlight.overview.routeReviewedTitle,
          subtitle: t.createFlight.overview.routeReviewedSubtitle(
            regions: _formatRegionCountLabel(context, regionCount),
            departure: RouteUtils.cityLabel(route.departure.city),
            arrival: RouteUtils.cityLabel(route.arrival.city),
          ),
          fullSummaryLabel: t.createFlight.overview.fullSummary,
          onFullSummary: widget.onRouteSummaryRequested,
          continueLabel: t.common.kContinue,
          onContinue: () => widget.onContinueFromOverview(false),
        );
    }
  }

  String _formatMinutesCompact(BuildContext context, int minutes) {
    final timelineT = context.t.createFlight.overview.timeline;
    if (minutes <= 0) {
      return '0 ${timelineT.minuteUnit}';
    }
    if (minutes < 60) {
      return '$minutes ${timelineT.minuteUnit}';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) {
      return '$h${timelineT.hourCompactUnit}';
    }
    return '$h${timelineT.hourCompactUnit} $m${timelineT.minuteCompactUnit}';
  }

  void _animateToNextCard() {
    final nextIndex = (_controller.page?.round() ?? widget.initialPage) + 1;
    if (nextIndex >= widget.entries.length) return;
    _controller.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatRegionCountLabel(BuildContext context, int count) {
    final label = context.t.createFlight.overview.routeSummaryRegionsLabel
        .toLowerCase();
    if (count == 1) {
      return '1 ${label.endsWith('s') ? label.substring(0, label.length - 1) : label}';
    }
    return '$count $label';
  }

  Future<void> _openRegionInfo(
    BuildContext context, {
    required RouteRegion region,
    required String typeLabel,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegionInfoScreen(region: region, typeLabel: typeLabel),
      ),
    );
  }
}
