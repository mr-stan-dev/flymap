import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/ui/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flutter/material.dart';

class FlightInfo extends StatelessWidget {
  final FlightPreviewAirports airports;

  const FlightInfo({super.key, required this.airports});

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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
        ],
      ),
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${airport.airportName}\n', // For 2 lines
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
