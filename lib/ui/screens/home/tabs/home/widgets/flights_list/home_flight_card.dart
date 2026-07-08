import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/policy/route_region_timeline_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/size_utils.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/complete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_route_preview_strip.dart';
import 'package:flymap/ui/theme/app_colours.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class HomeFlightCard extends StatelessWidget {
  const HomeFlightCard({
    required this.flight,
    required this.distanceUnit,
    required this.dateDisplayFormat,
    this.highlightInProgress = false,
    super.key,
  });

  static const bool _shareRouteMenuEnabled = true;

  final Flight flight;
  final DistanceUnit distanceUnit;
  final DateDisplayFormat dateDisplayFormat;
  final bool highlightInProgress;

  @override
  Widget build(BuildContext context) {
    final showProStyling = flight.hasProAccess;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = flight.route;
    final departure = route.departure;
    final arrival = route.arrival;
    final distance = UnitFormatUtils.formatDistance(
      route.displayDistanceKm.toDouble(),
      distanceUnit,
    );
    final offlineSize = _formatOfflineSize(flight);
    final poiCount = flight.info.poi.length;
    final articleCount = flight.info.articles.length;
    final routeRegions = RouteRegionTimelinePolicy.forFlight(
      regions: flight.info.routeRegions,
      departureCountryCode: departure.countryCode,
      arrivalCountryCode: arrival.countryCode,
      totalRouteKm: route.distanceInKm,
      languageCode: LocaleSettings.currentLocale.languageCode,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppRouter.goToFlight(context, flight: flight),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        RouteUtils.routeCities(route),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        RouteUtils.routeCountries(context, route),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_FlightCardAction>(
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
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SavedFlightCardBody(
              distance: distance,
              offlineSize: offlineSize,
              createdLabel: _createdLabel(
                flight.createdAt,
                format: dateDisplayFormat,
              ),
              hasProAccess: showProStyling,
              poiCount: poiCount,
              articleCount: articleCount,
              departureCode: departure.displayCode,
              arrivalCode: arrival.displayCode,
              departureCountryCode: departure.countryCode,
              arrivalCountryCode: arrival.countryCode,
              routeRegions: routeRegions,
              showInProgressStatusChip: highlightInProgress,
            ),
          ],
        ),
      ),
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

  String _formatOfflineSize(Flight flight) {
    final bytes = _mapSizeBytes(flight);
    if (bytes <= 0) return t.home.noOfflineMap;
    return SizeUtils.formatBytes(bytes);
  }

  int _mapSizeBytes(Flight flight) {
    if (flight.maps.isEmpty) return 0;
    return flight.maps.fold<int>(0, (sum, map) => sum + map.sizeBytes);
  }

  String _createdLabel(
    DateTime createdAt, {
    required DateDisplayFormat format,
  }) {
    final delta = DateTime.now().difference(createdAt);
    final savedTime = delta.inDays >= 1
        ? UnitFormatUtils.formatDate(createdAt, format: format)
        : delta.inHours >= 1
        ? t.home.hoursAgo(hours: delta.inHours)
        : delta.inMinutes >= 1
        ? t.home.minutesAgo(minutes: delta.inMinutes)
        : t.home.justNow;
    return t.home.savedTime(time: savedTime);
  }

}

class _SavedFlightCardBody extends StatelessWidget {
  const _SavedFlightCardBody({
    required this.distance,
    required this.offlineSize,
    required this.createdLabel,
    required this.hasProAccess,
    required this.poiCount,
    required this.articleCount,
    required this.departureCode,
    required this.arrivalCode,
    required this.departureCountryCode,
    required this.arrivalCountryCode,
    required this.routeRegions,
    required this.showInProgressStatusChip,
  });

  final String distance;
  final String offlineSize;
  final String createdLabel;
  final bool hasProAccess;
  final int poiCount;
  final int articleCount;
  final String departureCode;
  final String arrivalCode;
  final String departureCountryCode;
  final String arrivalCountryCode;
  final List<RouteRegionMarker> routeRegions;
  final bool showInProgressStatusChip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MetaPill(icon: Icons.route, text: distance),
            MetaPill(
              icon: Icons.place_outlined,
              text: context.t.home.placesCount(count: poiCount),
            ),
            if (articleCount > 0)
              MetaPill(
                icon: Icons.menu_book_outlined,
                text: context.t.home.offlineArticlesCount(count: articleCount),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (showInProgressStatusChip)
          _InProgressChip()
        else
          Row(
            children: [
              if (hasProAccess) ...[
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 12,
                  color: DsBrandColors.proAmber,
                ),
                const SizedBox(width: 4),
                Text(
                  '• ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              Text(
                '$offlineSize • $createdLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        const SizedBox(height: 14),
        HomeRoutePreviewStrip(
          departureCode: departureCode,
          arrivalCode: arrivalCode,
          departureCountryCode: departureCountryCode,
          arrivalCountryCode: arrivalCountryCode,
          regions: routeRegions,
        ),
      ],
    );
  }
}

enum _FlightCardAction { open, share, completeFlight, deleteFlight }

class _InProgressChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColoursCommon.brandBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.t.settings.historyStatusInProgress,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColoursCommon.brandBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
