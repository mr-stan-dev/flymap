import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/entity/flight_route.dart';

class InfoActionBar extends StatelessWidget {
  const InfoActionBar({required this.route, super.key});

  final FlightRoute route;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _shareRoutePlaceholder(context),
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Share route'),
        ),
        OutlinedButton.icon(
          onPressed: () => _copyRouteCode(context),
          icon: const Icon(Icons.route, size: 16),
          label: const Text('Copy Route'),
        ),
      ],
    );
  }

  void _shareRoutePlaceholder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share route will be added soon')),
    );
  }

  Future<void> _copyRouteCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: route.routeCode));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Route code copied')));
    }
  }
}
