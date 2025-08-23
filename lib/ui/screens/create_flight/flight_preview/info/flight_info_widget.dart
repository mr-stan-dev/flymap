import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class FlightInfoWidget extends StatelessWidget {
  final FlightRoute route;
  final FlightInfo info;

  const FlightInfoWidget({
    super.key,
    required this.route,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flight route (~ ${MapUtils.distanceFormatted(departure: route.departure, arrival: route.arrival)})',
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
                  'Departure',
                  Icons.flight_takeoff,
                  primary,
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
              // Arrival airport
              Expanded(
                child: _buildAirportInfo(
                  context,
                  route.arrival,
                  'Arrival',
                  Icons.flight_land,
                  primary,
                ),
              ),
            ],
          ),
          info.isEmpty
              ? _flightPoiLoading(context)
              : _flightPoi(context, info),
        ],
      ),
    );
  }

  Widget _flightPoiLoading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Building route overview..',
              style: context.textTheme.body18Regular,
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 8),
            SizedBox.square(dimension: 12, child: CircularProgressIndicator()),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _flightPoi(BuildContext context, FlightInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (((info.overview)).trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Overview', style: context.textTheme.title24Medium),
          const SizedBox(height: 8),
          Text(info.overview, style: context.textTheme.body18Regular),
        ],
        if ((info.poi.isNotEmpty)) ...[
          const SizedBox(height: 24),
          Text('You\'ll fly over', style: context.textTheme.title24Medium),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
