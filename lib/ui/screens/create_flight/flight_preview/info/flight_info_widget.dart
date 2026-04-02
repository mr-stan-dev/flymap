import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/shared/flight_overview_content.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final t = context.t;
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
            style: context.textTheme.title24Medium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Departure airport
              Expanded(
                child: _buildAirportInfo(
                  context,
                  route.departure,
                  t.flight.info.departure,
                  Icons.flight_takeoff,
                  primary,
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              // Arrival airport
              Expanded(
                child: _buildAirportInfo(
                  context,
                  route.arrival,
                  t.flight.info.arrival,
                  Icons.flight_land,
                  primary,
                ),
              ),
            ],
          ),
          _flightPoi(context, info),
        ],
      ),
    );
  }

  Widget _flightPoi(BuildContext context, FlightInfo info) {
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
            style: context.textTheme.title24Medium,
          ),
          const SizedBox(height: 8),
          FlightOverviewContent(
            overview: info.overview,
            isLoading: isOverviewLoading,
            errorMessage: overviewErrorMessage,
            loadingMessage: context.t.flight.info.overviewLoading,
            emptyMessage: context.t.flight.info.overviewEmpty,
          ),
        ],
        if ((info.poi.isNotEmpty)) ...[
          const SizedBox(height: 24),
          Text(
            context.t.flight.info.flyOverTitle,
            style: context.textTheme.title24Medium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final poi in info.poi)
                if (poi.name.trim().isNotEmpty) Chip(label: Text(poi.name)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAirportInfo(
    BuildContext context,
    Airport airport,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.textTheme.body16Medium.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${airport.name}\n', // For 2 lines
            style: context.textTheme.body16Regular,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
