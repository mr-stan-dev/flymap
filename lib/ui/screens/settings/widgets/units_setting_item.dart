import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_state.dart';

import 'setting_item.dart';
import 'settings_bottom_sheet.dart';
import 'settings_choice_section.dart';

class UnitsSettingItem extends StatelessWidget {
  const UnitsSettingItem({required this.state, super.key});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return SettingItem(
      title: context.t.settings.units,
      leading: const Icon(Icons.straighten),
      subtitle:
          '${state.altitudeUnit} • ${state.speedUnit} • ${state.timeFormat}',
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
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SettingsBottomSheet(
            title: context.t.settings.units,
            onConfirm: () async {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsChoiceSection(
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
                SettingsChoiceSection(
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
                SettingsChoiceSection(
                  title: context.t.settings.timeFormat,
                  options: const ['24h', '12h'],
                  current: timeFormat,
                  onChanged: (value) {
                    setModalState(() {
                      timeFormat = value;
                    });
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
