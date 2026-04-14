import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_state.dart';

import 'units_section.dart';

class UnitsSettingItem extends StatelessWidget {
  const UnitsSettingItem({
    required this.state,
    super.key,
  });

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListTile(
      leading: const Icon(Icons.straighten),
      title: Text(context.t.settings.units, style: theme.textTheme.titleMedium),
      subtitle: Text(
        '${state.altitudeUnit} • ${state.speedUnit} • ${state.timeFormat}',
        style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => showUnitsSheet(context, initialState: state),
    );
  }
}

Future<void> showUnitsSheet(
  BuildContext context, {
  required SettingsState initialState,
}) async {
  final cubit = context.read<SettingsCubit>();
  var altitudeUnit = initialState.altitudeUnit;
  var speedUnit = initialState.speedUnit;
  var timeFormat = initialState.timeFormat;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.settings.units,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                UnitsSection(
                  title: context.t.settings.altitudeUnit,
                  options: const ['ft', 'm'],
                  current: altitudeUnit,
                  onChanged: (value) {
                    setModalState(() {
                      altitudeUnit = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                UnitsSection(
                  title: context.t.settings.speedUnit,
                  options: const ['km/h', 'mph'],
                  current: speedUnit,
                  onChanged: (value) {
                    setModalState(() {
                      speedUnit = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                UnitsSection(
                  title: context.t.settings.timeFormat,
                  options: const ['24h', '12h'],
                  current: timeFormat,
                  onChanged: (value) {
                    setModalState(() {
                      timeFormat = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TertiaryButton(
                        label: context.t.common.cancel,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: context.t.common.ok,
                        onPressed: () async {
                          if (altitudeUnit != initialState.altitudeUnit) {
                            await cubit.setAltitudeUnit(altitudeUnit);
                          }
                          if (speedUnit != initialState.speedUnit) {
                            await cubit.setSpeedUnit(speedUnit);
                          }
                          if (timeFormat != initialState.timeFormat) {
                            await cubit.setTimeFormat(timeFormat);
                          }
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
