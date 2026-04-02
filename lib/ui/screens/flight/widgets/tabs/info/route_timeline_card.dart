import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class RouteTimelineCard extends StatelessWidget {
  const RouteTimelineCard({required this.route, super.key});

  final FlightRoute route;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return SectionCard(
      title: t.flight.info.routeTimelineTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineRow(
            icon: Icons.flight_takeoff,
            label: '${route.departure.displayCode} • ${route.departure.city}',
          ),
          if (route.waypoints.isNotEmpty) ...[
            _connector(context),
            _TimelineRow(
              icon: Icons.more_horiz,
              label: t.flight.info.plannedWaypoints(
                count: route.waypoints.length,
              ),
            ),
          ],
          _connector(context),
          _TimelineRow(
            icon: Icons.flight_land,
            label: '${route.arrival.displayCode} • ${route.arrival.city}',
          ),
        ],
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
