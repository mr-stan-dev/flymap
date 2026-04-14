import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_state.dart';

import 'setting_item.dart';
import 'settings_bottom_sheet.dart';
import 'settings_choice_section.dart';

class ThemeSettingItem extends StatelessWidget {
  const ThemeSettingItem({required this.state, super.key});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    return SettingItem(
      title: context.t.settings.theme,
      subtitle: _themeModeLabel(context, state.themeMode),
      leading: const Icon(Icons.dark_mode),
      onTap: () => showThemeSheet(context, initialMode: state.themeMode),
    );
  }
}

Future<void> showThemeSheet(
  BuildContext context, {
  required ThemeMode initialMode,
}) async {
  final cubit = context.read<SettingsCubit>();
  var selectedMode = initialMode;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SettingsBottomSheet(
            title: context.t.settings.theme,
            onConfirm: () async {
              if (selectedMode != initialMode) {
                await cubit.setTheme(selectedMode);
              }
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: SettingsChoiceSection(
              options: [
                context.t.settings.system,
                context.t.settings.dark,
                context.t.settings.light,
              ],
              current: _themeModeLabel(context, selectedMode),
              onChanged: (value) {
                setModalState(() {
                  selectedMode = switch (value) {
                    final modeLabel when modeLabel == context.t.settings.dark =>
                      ThemeMode.dark,
                    final modeLabel
                        when modeLabel == context.t.settings.light =>
                      ThemeMode.light,
                    _ => ThemeMode.system,
                  };
                });
              },
            ),
          );
        },
      );
    },
  );
}

String _themeModeLabel(BuildContext context, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.dark => context.t.settings.dark,
    ThemeMode.light => context.t.settings.light,
    ThemeMode.system => context.t.settings.system,
  };
}
