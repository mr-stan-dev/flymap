import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
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
            const SizedBox(width: DsSpacing.xs),
            Text(
              context.t.flight.dashboard.gpsOffTitle,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: DsSpacing.xs),
        Text(
          context.t.flight.dashboard.gpsOffSubtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: DsSpacing.sm),
        PrimaryButton(
          onPressed: () {
            context.read<FlightScreenCubit>().openLocationSettings();
          },
          leadingIcon: Icons.settings,
          label: context.t.flight.dashboard.openLocationSettings,
          expand: false,
        ),
      ],
    );
  }
}
