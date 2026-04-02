import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';

class RouteFactsWrap extends StatelessWidget {
  const RouteFactsWrap({required this.route, super.key});

  final FlightRoute route;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FactChip(
          icon: Icons.route,
          label: context.t.flight.info.distanceKm(
            distance: route.distanceInKm.toStringAsFixed(0),
          ),
        ),
        _FactChip(
          icon: Icons.flight_takeoff,
          label: route.departure.displayCode,
        ),
        _FactChip(icon: Icons.flight_land, label: route.arrival.displayCode),
      ],
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
