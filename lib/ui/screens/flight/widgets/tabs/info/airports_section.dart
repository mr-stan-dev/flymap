import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class AirportsSection extends StatelessWidget {
  const AirportsSection({required this.route, super.key});

  final FlightRoute route;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: 'Airports',
      child: Column(
        children: [
          _AirportTile(
            icon: Icons.flight_takeoff,
            title: 'Departure',
            code: route.departure.displayCode,
            subtitle:
                '${route.departure.name}, ${route.departure.city}, ${route.departure.countryCode}',
          ),
          const SizedBox(height: 8),
          _AirportTile(
            icon: Icons.flight_land,
            title: 'Arrival',
            code: route.arrival.displayCode,
            subtitle:
                '${route.arrival.name}, ${route.arrival.city}, ${route.arrival.countryCode}',
          ),
        ],
      ),
    );
  }
}

class _AirportTile extends StatelessWidget {
  const _AirportTile({
    required this.icon,
    required this.title,
    required this.code,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String code;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title • $code',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
