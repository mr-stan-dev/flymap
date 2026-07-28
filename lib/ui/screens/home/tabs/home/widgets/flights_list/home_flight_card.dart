import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/policy/route_region_timeline_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/complete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flight_card_map_header.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_route_preview_strip.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/travel_date_format_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class HomeFlightCard extends StatelessWidget {
  const HomeFlightCard({
    required this.flight,
    required this.distanceUnit,
    this.highlightInProgress = false,
    super.key,
  });

  static const bool _shareRouteMenuEnabled = true;

  final Flight flight;
  final DistanceUnit distanceUnit;
  final bool highlightInProgress;

  @override
  Widget build(BuildContext context) {
    final showProStyling = flight.hasProAccess;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = flight.route;
    final departure = route.departure;
    final arrival = route.arrival;
    final distance = UnitFormatUtils.formatDistanceApprox(
      route.displayDistanceKm.toDouble(),
      distanceUnit,
    );
    final duration = DurationFormatUtils.formatApprox(
      context,
      route.durations.displayBlockMinutes,
    );
    final flightNumber = flight.operationalData?.flightNumber.trim();
    final regionCount = flight.info.routeRegions.length;
    final poiCount = flight.info.poi.length;
    final subtitle = [
      if (flightNumber != null && flightNumber.isNotEmpty) flightNumber,
      if (regionCount > 0) context.t.home.regionsCount(count: regionCount),
      if (poiCount > 0) context.t.home.placesCount(count: poiCount),
    ].join(' • ');
    final routeRegions = RouteRegionTimelinePolicy.forFlight(
      regions: flight.info.routeRegions,
      departureCountryCode: departure.countryCode,
      arrivalCountryCode: arrival.countryCode,
      totalRouteKm: route.distanceInKm,
      languageCode: LocaleSettings.currentLocale.languageCode,
    );

    final cardColor = highlightInProgress
        ? Color.alphaBlend(
            AppColoursCommon.brandBlue.withValues(alpha: 0.06),
            colorScheme.surfaceContainerLowest,
          )
        : colorScheme.surfaceContainerLowest;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppRouter.goToFlight(context, flight: flight),
      child: Ink(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlightInProgress
                ? AppColoursCommon.brandBlue
                : colorScheme.outline.withValues(alpha: 0.2),
            width: highlightInProgress ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeFlightCardMapHeader(
              flight: flight,
              cardColor: cardColor,
              title: RouteUtils.routeCities(route),
              subtitle: subtitle,
              showProCrown: showProStyling,
              menuButton: _buildMenuButton(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: _SavedFlightCardBody(
                distance: distance,
                duration: duration,
                travelDateLabel: TravelDateFormatUtils.countdownLabel(
                  flight.schedule,
                ),
                departureCode: departure.displayCode,
                arrivalCode: arrival.displayCode,
                departureCountryCode: departure.countryCode,
                arrivalCountryCode: arrival.countryCode,
                routeRegions: routeRegions,
                showInProgressStatusChip: highlightInProgress,
                planeProgress: _estimatedRouteProgress(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<_FlightCardAction>(
      tooltip: context.t.home.flightActions,
      onSelected: (value) =>
          _onActionSelected(context, value: value, flight: flight),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _FlightCardAction.open,
          child: Text(context.t.home.open),
        ),
        if (_shareRouteMenuEnabled)
          PopupMenuItem(
            value: _FlightCardAction.share,
            child: Text(context.t.home.shareRoute),
          ),
        PopupMenuItem(
          value: _FlightCardAction.flightVideo,
          child: Text(context.t.flightVideo.title),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: _FlightCardAction.completeFlight,
          child: Text(context.t.home.completeFlight),
        ),
        PopupMenuItem(
          value: _FlightCardAction.deleteFlight,
          child: Text(context.t.home.deleteFlight),
        ),
      ],
    );
  }

  Future<void> _onActionSelected(
    BuildContext context, {
    required _FlightCardAction value,
    required Flight flight,
  }) async {
    switch (value) {
      case _FlightCardAction.open:
        AppRouter.goToFlight(context, flight: flight);
      case _FlightCardAction.share:
        AppRouter.goToShareImage(context, flightId: flight.id);
      case _FlightCardAction.flightVideo:
        AppRouter.goToFlightVideo(context, flightId: flight.id);
      case _FlightCardAction.completeFlight:
        final result = await CompleteFlightConfirmationDialog.show(context);
        if (result == null || !context.mounted) return;
        final completed = await context.read<HomeTabCubit>().completeFlight(
          flightId: flight.id,
          deleteOfflineData: result.deleteOfflineData,
        );
        if (!completed && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.home.failedDeleteFlight)),
          );
        }
      case _FlightCardAction.deleteFlight:
        final confirmed = await DeleteFlightConfirmationDialog.show(
          context,
          reclaimedBytes: _mapSizeBytes(flight),
        );
        if (confirmed != true || !context.mounted) return;
        final deleted = await context.read<HomeTabCubit>().deleteFlight(
          flight.id,
        );
        if (!deleted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.home.failedDeleteFlight)),
          );
        }
    }
  }

  int _mapSizeBytes(Flight flight) {
    if (flight.maps.isEmpty) return 0;
    return flight.maps.fold<int>(0, (sum, map) => sum + map.sizeBytes);
  }

  /// Time-based estimate of how far along the route an in-progress flight is
  /// (no GPS on the home screen); null for flights that are not in progress.
  double? _estimatedRouteProgress() {
    if (!highlightInProgress) return null;
    final startedAt = flight.inProgressAt;
    final totalMinutes = flight.route.durations.displayBlockMinutes;
    if (startedAt == null || totalMinutes <= 0) return 0.5;
    final elapsedMinutes = DateTime.now().difference(startedAt).inMinutes;
    return (elapsedMinutes / totalMinutes).clamp(0.04, 0.96).toDouble();
  }
}

class _SavedFlightCardBody extends StatelessWidget {
  const _SavedFlightCardBody({
    required this.distance,
    required this.duration,
    required this.travelDateLabel,
    required this.departureCode,
    required this.arrivalCode,
    required this.departureCountryCode,
    required this.arrivalCountryCode,
    required this.routeRegions,
    required this.showInProgressStatusChip,
    required this.planeProgress,
  });

  final String distance;
  final String? duration;
  final String? travelDateLabel;
  final String departureCode;
  final String arrivalCode;
  final String departureCountryCode;
  final String arrivalCountryCode;
  final List<RouteRegionMarker> routeRegions;
  final bool showInProgressStatusChip;
  final double? planeProgress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (travelDateLabel != null)
              MetaPill(icon: Icons.event_rounded, text: travelDateLabel!),
            MetaPill(icon: Icons.route, text: distance),
            if (duration != null)
              MetaPill(icon: Icons.schedule_rounded, text: duration!),
            if (showInProgressStatusChip) _InProgressChip(),
          ],
        ),
        const SizedBox(height: 14),
        HomeRoutePreviewStrip(
          departureCode: departureCode,
          arrivalCode: arrivalCode,
          departureCountryCode: departureCountryCode,
          arrivalCountryCode: arrivalCountryCode,
          regions: routeRegions,
          planeProgress: planeProgress,
        ),
      ],
    );
  }
}

enum _FlightCardAction {
  open,
  share,
  flightVideo,
  completeFlight,
  deleteFlight,
}

/// Matches [MetaPill] dimensions and shape so it lines up with the other
/// chips in the row, but in brand blue with a gently pulsing dot — the
/// "live" cue that this flight is happening right now.
class _InProgressChip extends StatefulWidget {
  @override
  State<_InProgressChip> createState() => _InProgressChipState();
}

class _InProgressChipState extends State<_InProgressChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final Animation<double> _dotOpacity = Tween<double>(
    begin: 0.25,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColoursCommon.brandBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DsRadii.sm),
        border: Border.all(
          color: AppColoursCommon.brandBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _dotOpacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColoursCommon.brandBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.t.settings.historyStatusInProgress,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColoursCommon.brandBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
