import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';

class GpsOffState extends StatelessWidget {
  const GpsOffState({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gps_off_rounded, color: colorScheme.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Location services are off',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Turn on location services in system settings to resume live flight tracking and map following.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () {
            context.read<FlightScreenCubit>().openLocationSettings();
          },
          icon: const Icon(Icons.settings, size: 16),
          label: const Text('Open location settings'),
        ),
      ],
    );
  }
}
