import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'viewmodel/settings_cubit.dart';
import 'viewmodel/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the app-level SettingsCubit provided in main.dart
    return const _SettingsView();
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              _SettingItem(
                title: 'Theme',
                subtitle: state.themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                leading: const Icon(Icons.dark_mode),
                onTap: () async {
                  final selected = await _showOptions(
                    context,
                    title: 'Theme',
                    options: const ['Dark', 'Light'],
                    current: state.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : 'Light',
                  );
                  if (selected != null) {
                    context.read<SettingsCubit>().setTheme(
                      selected == 'Dark' ? ThemeMode.dark : ThemeMode.light,
                    );
                  }
                },
              ),
              const Divider(height: 1),
              _SettingItem(
                title: 'Altitude',
                subtitle: state.altitudeUnit,
                leading: const Icon(Icons.height),
                onTap: () async {
                  final selected = await _showOptions(
                    context,
                    title: 'Altitude unit',
                    options: const ['ft', 'm'],
                    current: state.altitudeUnit,
                  );
                  if (selected != null) {
                    context.read<SettingsCubit>().setAltitudeUnit(selected);
                  }
                },
              ),
              const Divider(height: 1),
              _SettingItem(
                title: 'Speed',
                subtitle: state.speedUnit,
                leading: const Icon(Icons.speed),
                onTap: () async {
                  final selected = await _showOptions(
                    context,
                    title: 'Speed unit',
                    options: const ['km/h', 'mph'],
                    current: state.speedUnit,
                  );
                  if (selected != null) {
                    context.read<SettingsCubit>().setSpeedUnit(selected);
                  }
                },
              ),
              const Divider(height: 1),
              _SettingItem(
                title: 'Time format',
                subtitle: state.timeFormat,
                leading: const Icon(Icons.access_time),
                onTap: () async {
                  final selected = await _showOptions(
                    context,
                    title: 'Time format',
                    options: const ['24h', '12h'],
                    current: state.timeFormat,
                  );
                  if (selected != null) {
                    context.read<SettingsCubit>().setTimeFormat(selected);
                  }
                },
              ),
              const Divider(height: 1),
              _SettingItem(
                title: 'About',
                subtitle: 'Learn more about the app',
                leading: const Icon(Icons.info_outline),
                onTap: () async {
                  await _openExternalUrl(context, 'https://flymap.app/');
                },
              ),
              const Divider(height: 1),
              _SettingItem(
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                leading: const Icon(Icons.privacy_tip_outlined),
                onTap: () async {
                  await _openExternalUrl(
                    context,
                    'https://flymap.app/privacy-policy',
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  Future<String?> _showOptions(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (opt) => RadioListTile<String>(
                    title: Text(opt),
                    value: opt,
                    groupValue: current,
                    onChanged: (v) => Navigator.of(ctx).pop(v),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Icon? leading;
  final VoidCallback onTap;

  const _SettingItem({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface.withOpacity(0.7);

    return ListTile(
      leading: leading,
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(color: onSurface))
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
