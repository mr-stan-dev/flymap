import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_palette.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_shell.dart';

/// Opt-in card shown in place of the cabin-pressure tile on iOS when Motion &
/// Fitness has not been granted yet. Tapping the button requests it — we never
/// prompt automatically on screen entry.
class CabinPressureEnableCard extends StatelessWidget {
  const CabinPressureEnableCard({required this.onEnable, super.key});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final palette = InstrumentPalette.of(context);
    final t = context.t.flight.dashboard;
    return InstrumentPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelLabel(t.cabinPressure),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.speed_rounded,
                color: palette.secondaryText,
                size: 28,
              ),
              const SizedBox(width: DsSpacing.sm),
              Expanded(
                child: Text(
                  t.cabinPressureEnableBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onEnable,
              child: Text(t.cabinPressureEnableButton),
            ),
          ),
        ],
      ),
    );
  }
}
