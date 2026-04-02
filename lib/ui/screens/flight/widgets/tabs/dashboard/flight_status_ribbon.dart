import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';

class FlightStatusRibbon extends StatelessWidget {
  const FlightStatusRibbon({
    required this.route,
    required this.gpsData,
    super.key,
  });

  final FlightRoute route;
  final GpsData? gpsData;

  @override
  Widget build(BuildContext context) {
    final course = gpsData?.course ?? 0;
    final heading = '${course.toStringAsFixed(0)}° ${_cardinal(course)}';
    final lat = gpsData?.latitude;
    final lon = gpsData?.longitude;
    final position = lat == null || lon == null
        ? '--'
        : '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.flight.dashboard.navigation,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                icon: Icons.route_outlined,
                label:
                    '${route.departure.displayCode} → ${route.arrival.displayCode}',
              ),
              _Pill(
                icon: Icons.explore_outlined,
                label: context.t.flight.dashboard.heading(heading: heading),
              ),
              _Pill(icon: Icons.place_outlined, label: position),
            ],
          ),
        ],
      ),
    );
  }

  String _cardinal(double degrees) {
    final normalized = ((degrees % 360) + 360) % 360;
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final idx = ((normalized + 22.5) / 45).floor() % 8;
    return dirs[idx];
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
