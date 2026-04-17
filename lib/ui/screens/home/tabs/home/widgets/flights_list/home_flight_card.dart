import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/route_poi_rank.dart';
import 'package:flymap/entity/route_poi_summary.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/size_utils.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_route_preview_strip.dart';

class HomeFlightCard extends StatelessWidget {
  const HomeFlightCard({required this.flight, super.key});

  // TODO: Re-enable share route menu item after we fix android snapshot.
  static const bool _shareRouteMenuEnabled = false;

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final route = flight.route;
    final departure = route.departure;
    final arrival = route.arrival;
    final distanceKm = route.distanceInKm.toStringAsFixed(0);
    final offlineSize = _formatOfflineSize(flight);
    final poiCount = flight.info.poi.length;
    final articleCount = flight.info.articles.length;
    final routePreviewPoi = _selectRoutePreviewPoi(flight.info.poi);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => AppRouter.goToFlight(context, flight: flight),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
                      Row(
                        children: [
                          Text(
                            departure.displayCode,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            arrival.displayCode,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            departure.cityWithCountryCode,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.circle_rounded,
                            size: 4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            arrival.cityWithCountryCode,
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
                      value: _FlightCardAction.delete,
                      child: Text(context.t.home.deleteFlight),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SavedFlightCardBody(
              distanceKm: distanceKm,
              offlineSize: offlineSize,
              createdLabel: _createdLabel(flight.createdAt),
              poiCount: poiCount,
              articleCount: articleCount,
              departureCode: departure.displayCode,
              arrivalCode: arrival.displayCode,
              routePreviewPoi: routePreviewPoi,
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
        AppRouter.goToShareFlight(context, flight: flight);
      case _FlightCardAction.delete:
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

  String _createdLabel(DateTime createdAt) {
    final delta = DateTime.now().difference(createdAt);
    if (delta.inDays >= 1) return t.home.daysAgo(days: delta.inDays);
    if (delta.inHours >= 1) return t.home.hoursAgo(hours: delta.inHours);
    if (delta.inMinutes >= 1) {
      return t.home.minutesAgo(minutes: delta.inMinutes);
    }
    return t.home.justNow;
  }

  List<RoutePoiSummary> _selectRoutePreviewPoi(List<RoutePoiSummary> allPoi) {
    if (allPoi.isEmpty) return const [];

    final sorted = [...allPoi]
      ..sort((a, b) {
        final aScore = RoutePoiRank.baseScore(
          type: a.type,
          sitelinks: a.sitelinks,
        );
        final bScore = RoutePoiRank.baseScore(
          type: b.type,
          sitelinks: b.sitelinks,
        );
        return bScore.compareTo(aScore);
      });

    final selected = <RoutePoiSummary>[];
    final selectedQids = <String>{};

    void addMatching(FlightPoiType type, int maxCount) {
      for (final poi in sorted) {
        if (selected.length >= 3) return;
        if (poi.type != type || selectedQids.contains(poi.qid)) continue;
        selected.add(poi);
        selectedQids.add(poi.qid);
        if (selected.where((item) => item.type == type).length >= maxCount) {
          return;
        }
      }
    }

    addMatching(FlightPoiType.volcano, 2);
    addMatching(FlightPoiType.mountain, 1);
    addMatching(FlightPoiType.island, 1);

    for (final poi in sorted) {
      if (selected.length >= 3) break;
      if (selectedQids.contains(poi.qid)) continue;
      selected.add(poi);
      selectedQids.add(poi.qid);
    }

    selected.sort((a, b) {
      final aProgress = a.routeProgress ?? 0.5;
      final bProgress = b.routeProgress ?? 0.5;
      return aProgress.compareTo(bProgress);
    });
    return selected;
  }
}

class _SavedFlightCardBody extends StatelessWidget {
  const _SavedFlightCardBody({
    required this.distanceKm,
    required this.offlineSize,
    required this.createdLabel,
    required this.poiCount,
    required this.articleCount,
    required this.departureCode,
    required this.arrivalCode,
    required this.routePreviewPoi,
  });

  final String distanceKm;
  final String offlineSize;
  final String createdLabel;
  final int poiCount;
  final int articleCount;
  final String departureCode;
  final String arrivalCode;
  final List<RoutePoiSummary> routePreviewPoi;

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
            MetaPill(
              icon: Icons.route,
              text: context.t.flight.info.distanceKm(distance: distanceKm),
            ),
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
        Text(
          '$offlineSize • $createdLabel',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        HomeRoutePreviewStrip(
          departureCode: departureCode,
          arrivalCode: arrivalCode,
          poi: routePreviewPoi,
        ),
      ],
    );
  }
}

enum _FlightCardAction { open, share, delete }
