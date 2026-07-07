import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/distance_unit_context.dart';
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
    final distanceLabel = UnitFormatUtils.formatDistance(
      route.displayDistanceKm.toDouble(),
      context.distanceUnit,
    );
    final durationLabel = _formatMinutesCompact(context, totalMinutes);
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

  String _formatMinutesCompact(BuildContext context, int minutes) {
    final timelineT = context.t.createFlight.overview.timeline;
    if (minutes <= 0) {
      return '0 ${timelineT.minuteUnit}';
    }
    if (minutes < 60) {
      return '$minutes ${timelineT.minuteUnit}';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) {
      return '$h${timelineT.hourCompactUnit}';
    }
    return '$h${timelineT.hourCompactUnit} $m${timelineT.minuteCompactUnit}';
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
