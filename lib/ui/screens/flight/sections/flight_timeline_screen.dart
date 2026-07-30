import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/region_info_screen.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/route_progress_card.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/route/widgets/info_content.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/shared/tab_state_placeholder.dart';
import 'package:flymap/ui/screens/shared/premium/route_premium_gate_interactions.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_grouping.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_region_type_mapper.dart';
import 'package:flymap/ui/screens/shared/route_timeline/route_timeline_widget.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/utils/wikipedia_article_utils.dart';

/// Region-by-region timeline of the flight, pushed from the Flight hub.
/// Live progress (GPS) stays wired through the shared [FlightScreenCubit].
class FlightTimelineScreen extends StatelessWidget {
  const FlightTimelineScreen({super.key});

  static const _typeMapper = RouteTimelineRegionTypeMapper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.flight.hub.timelineTitle)),
      body: SafeArea(
        child: BlocBuilder<FlightScreenCubit, FlightScreenState>(
          builder: (context, state) {
            final loaded = switch (state) {
              FlightScreenLoaded() => state,
              FlightScreenError(:final flight?) => FlightScreenLoaded(
                flight: flight,
                routeRegions: flight.info.routeRegions,
              ),
              _ => null,
            };
            if (loaded == null) {
              return FlightTabStatePlaceholder(
                icon: Icons.timeline,
                text: context.t.flight.route.loadingRouteTimeline,
              );
            }
            return _TimelineBody(state: loaded);
          },
        ),
      ),
    );
  }

  static Future<void> openRegionInfo(
    BuildContext context,
    RouteRegion region,
    List<FlightArticle> articles,
  ) async {
    final typeLabel = _typeMapper.mapLabel(context, region.regionType);
    final offlineArticle = WikipediaArticleUtils.matchRegionArticle(
      region,
      articles,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegionInfoScreen(
          region: region,
          typeLabel: typeLabel,
          offlineMode: true,
          offlineArticle: offlineArticle,
        ),
      ),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody({required this.state});

  final FlightScreenLoaded state;

  @override
  Widget build(BuildContext context) {
    final info = state.flight.info;
    final isCurrentUserPro = context.select(
      (SubscriptionCubit cubit) => cubit.state.isPro,
    );
    final isProUser = isCurrentUserPro || state.flight.hasProAccess;
    final routeRegions = state.routeRegions;
    final route = state.flight.route;
    final routeCruiseSpeedKmh =
        route.metrics.cruiseSpeedKmh?.round() ?? info.routeCruiseSpeedKmh;
    final displayBlockMinutes = route.durations.displayBlockMinutes;
    final routeBlockMinutes = displayBlockMinutes > 0
        ? displayBlockMinutes
        : info.routeCruiseMinutes;
    final hasRegionTimeline = routeRegions.isNotEmpty;
    final hasOverview = info.overview.trim().isNotEmpty;

    if (!hasRegionTimeline && hasOverview) {
      return FlightInfoContent(topPadding: 12, route: route, info: info);
    }

    final groups = RouteTimelineGrouping.groupByTimeline(
      routeRegions,
      cruiseSpeedKmh: routeCruiseSpeedKmh,
      maxTimelineMinutes: route.isHistoricalTrack ? routeBlockMinutes : null,
      routeDistanceKm: route.distanceInKm,
      blockMinutes: routeBlockMinutes,
      useTotalDurationProportion: !route.isHistoricalTrack,
    );
    final timelineTotalMinutes = RouteTimelineGrouping.arrivalMinutes(
      routeDistanceKm: route.distanceInKm,
      blockMinutes: routeBlockMinutes,
      cruiseSpeedKmh: routeCruiseSpeedKmh,
      groups: groups,
      blockMinutesIsAuthoritative: route.isHistoricalTrack,
    );

    final isUpcoming = state.flight.status == FlightStatus.upcoming;
    final hasGpsFix =
        state.gps.data?.latitude != null && state.gps.data?.longitude != null;
    final isGpsStale =
        state.gps.status == GpsStatus.searching && state.gps.lastFixAt != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isUpcoming && hasGpsFix) ...[
            RouteProgressCard(
              route: route,
              coveredDistanceKm: state.routeCoveredDistanceKm,
              isStale: isGpsStale,
            ),
            const SizedBox(height: DsSpacing.sm),
          ],
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
              child: Text(
                context.t.flight.route.noSavedOfflineRegions,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          RouteTimelineWidget(
            route: route,
            regions: routeRegions,
            isProUser: isProUser,
            cruiseSpeedKmh: routeCruiseSpeedKmh,
            blockMinutes: timelineTotalMinutes,
            lastVisitedRegionId: state.lastVisitedRegionId,
            onPremiumGateTap: () => RoutePremiumGateInteractions.onGateTap(
              context: context,
              source: PaywallSource.routeTimelineGate,
              useOfflineInfoSheet: true,
            ),
            onOpenRegion: (region) => FlightTimelineScreen.openRegionInfo(
              context,
              region,
              state.flight.info.articles,
            ),
          ),
        ],
      ),
    );
  }
}
