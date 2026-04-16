import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_highlights_section.dart';
import 'package:flymap/ui/screens/shared/airport_info_tile.dart';
import 'package:flymap/ui/screens/shared/flight_overview_content.dart';

class FlightInfoWidget extends StatelessWidget {
  final FlightRoute route;
  final FlightInfo info;
  final bool isOverviewLoading;
  final String? overviewErrorMessage;

  const FlightInfoWidget({
    super.key,
    required this.route,
    required this.info,
    this.isOverviewLoading = false,
    this.overviewErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.preview.flightRoute(
              distance: MapUtils.distanceFormatted(
                departure: route.departure,
                arrival: route.arrival,
              ),
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              AirportInfoTile(
                icon: Icons.flight_takeoff,
                title: t.flight.info.departure,
                code: route.departure.displayCode,
                subtitle:
                    '${route.departure.name}, ${route.departure.city}, ${route.departure.countryCode}',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colorScheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.circle, size: 8, color: colorScheme.outline.withValues(alpha: 0.45)),
                    ),
                    Expanded(
                      child: Divider(
                        color: colorScheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                  ],
                ),
              ),
              AirportInfoTile(
                icon: Icons.flight_land,
                title: t.flight.info.arrival,
                code: route.arrival.displayCode,
                subtitle:
                    '${route.arrival.name}, ${route.arrival.city}, ${route.arrival.countryCode}',
              ),
            ],
          ),
          _flightOverview(context, info),
        ],
      ),
    );
  }

  Widget _flightOverview(BuildContext context, FlightInfo info) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasOverviewSignal =
        isOverviewLoading ||
        (overviewErrorMessage?.trim().isNotEmpty ?? false) ||
        info.overview.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasOverviewSignal) ...[
          const SizedBox(height: 24),
          Text(
            context.t.flight.info.overviewTitle,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.42,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.10),
              ),
            ),
            child: FlightOverviewContent(
              overview: info.overview,
              isLoading: isOverviewLoading,
              errorMessage: overviewErrorMessage,
              loadingMessage: context.t.flight.info.overviewLoading,
              emptyMessage: context.t.flight.info.overviewEmpty,
            ),
          ),
        ],
        if ((info.poi.isNotEmpty)) ...[
          const SizedBox(height: 24),
          Text(
            '${context.t.flight.info.flyOverTitle} · ${info.poi.length}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          PoiHighlightsSection(poi: info.poi),
        ],
      ],
    );
  }
}
