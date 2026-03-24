import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/route_copy_builder.dart';

class InfoActionBar extends StatelessWidget {
  const InfoActionBar({required this.flight, super.key});

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _openShareRouteScreen(context),
          icon: const Icon(Icons.share, size: 16),
          label: const Text('Share route'),
        ),
        OutlinedButton.icon(
          onPressed: () => _copyRouteSummary(context),
          icon: const Icon(Icons.route, size: 16),
          label: const Text('Copy Route'),
        ),
      ],
    );
  }

  void _openShareRouteScreen(BuildContext context) {
    AppRouter.goToShareFlight(context, flight: flight);
  }

  Future<void> _copyRouteSummary(BuildContext context) async {
    final routeSummary = RouteCopyBuilder.build(flight.route);
    await Clipboard.setData(ClipboardData(text: routeSummary));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Route summary copied')));
    }
  }
}
