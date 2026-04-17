import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class HomeFlightsEmptyState extends StatelessWidget {
  const HomeFlightsEmptyState({required this.onAddFirstFlight, super.key});

  final VoidCallback onAddFirstFlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flight_takeoff,
            color: colorScheme.onSurfaceVariant,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            context.t.home.noFlightsTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.t.home.noFlightsSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SecondaryButton(
            label: context.t.home.addFirstFlight,
            leadingIcon: Icons.add,
            onPressed: onAddFirstFlight,
          ),
        ],
      ),
    );
  }
}
