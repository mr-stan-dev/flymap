import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';

class RouteTimelineCard extends StatelessWidget {
  const RouteTimelineCard({required this.route, super.key});

  final FlightRoute route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route timeline',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            _TimelineRow(
              icon: Icons.flight_takeoff,
              label: '${route.departure.displayCode} • ${route.departure.city}',
            ),
            if (route.waypoints.isNotEmpty) ...[
              _connector(context),
              _TimelineRow(
                icon: Icons.more_horiz,
                label: '${route.waypoints.length} planned waypoints',
              ),
            ],
            _connector(context),
            _TimelineRow(
              icon: Icons.flight_land,
              label: '${route.arrival.displayCode} • ${route.arrival.city}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _connector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        width: 2,
        height: 14,
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    );
  }
}
