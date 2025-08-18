import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class FlightInfoWidget extends StatelessWidget {
  final FlightPreviewAirports airports;
  final FlightInfo flightInfo;

  const FlightInfoWidget({
    super.key,
    required this.airports,
    required this.flightInfo,
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
            'Flight route (~ ${MapUtils.distanceFormatted(departure: airports.departure, arrival: airports.arrival)})',
            style: context.textTheme.title24Medium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Departure airport
              Expanded(
                child: _buildAirportInfo(
                  context,
                  airports.departure,
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
                  airports.arrival,
                  'Arrival',
                  Icons.flight_land,
                  primary,
                ),
              ),
            ],
          ),
          flightInfo.isEmpty
              ? _flightPoiLoading(context)
              : _flightPoi(context, flightInfo),
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
        if (((flightInfo.overview)).trim().isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Overview', style: context.textTheme.title24Medium),
          const SizedBox(height: 8),
          Text(flightInfo.overview, style: context.textTheme.body18Regular),
        ],
        if ((flightInfo.poi.isNotEmpty)) ...[
          const SizedBox(height: 24),
          Text('You\'ll fly over', style: context.textTheme.title24Medium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final poi in flightInfo.poi)
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
            '${airport.airportName}\n', // For 2 lines
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
