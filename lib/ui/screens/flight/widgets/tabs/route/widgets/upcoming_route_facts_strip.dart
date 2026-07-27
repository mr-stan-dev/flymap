import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
import 'package:flymap/utils/duration_format_utils.dart';
import 'package:flymap/utils/unit_format_utils.dart';

class UpcomingRouteFactsStrip extends StatelessWidget {
  const UpcomingRouteFactsStrip({
    required this.route,
    required this.totalMinutes,
    super.key,
  });

  final FlightRoute route;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = UnitFormatUtils.formatDistanceApprox(
      route.displayDistanceKm.toDouble(),
      context.distanceUnit,
    );
    final durationLabel =
        DurationFormatUtils.formatApprox(context, totalMinutes) ??
        '0 ${context.t.createFlight.overview.timeline.minuteUnit}';
    final routeLabel =
        '${route.departure.displayCode} → ${route.arrival.displayCode}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.t.flight.info.departure} • ${route.departure.displayCode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              route.departure.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              '${context.t.flight.info.arrival} • ${route.arrival.displayCode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              route.arrival.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FactChip(icon: Icons.route, label: distanceLabel),
                _FactChip(icon: Icons.schedule, label: durationLabel),
                _FactChip(icon: Icons.flight, label: routeLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14), const SizedBox(width: 6), Text(label)],
      ),
    );
  }
}
