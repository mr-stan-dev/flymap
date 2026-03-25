import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flymap/router/app_router.dart';

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
            return const LoadingStateView(title: 'Loading settings...');
          }
          final theme = Theme.of(context);
          final sectionBg = theme.colorScheme.surfaceContainerHighest;
          return ListView(
            children: [
              // Appearance section
              Container(
                width: double.infinity,
                color: sectionBg,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(
                  'Appearance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                  if (!context.mounted) return;
                  if (selected != null) {
                    context.read<SettingsCubit>().setTheme(
                      selected == 'Dark' ? ThemeMode.dark : ThemeMode.light,
                    );
                  }
                },
              ),
              const Divider(height: 1),

              // Units section
              Container(
                width: double.infinity,
                color: sectionBg,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(
                  'Units',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                  if (!context.mounted) return;
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
                  if (!context.mounted) return;
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
                  if (!context.mounted) return;
                  if (selected != null) {
                    context.read<SettingsCubit>().setTimeFormat(selected);
                  }
                },
              ),

              // About section
              Container(
                width: double.infinity,
                color: sectionBg,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Text(
                  'About',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _SettingItem(
                title: 'About',
                subtitle: 'Learn more about the app',
                leading: const Icon(Icons.info_outline),
                onTap: () {
                  AppRouter.goToAbout(context);
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
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map(
                      (opt) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(opt),
                        trailing: opt == current
                            ? Icon(
                                Icons.check_circle,
                                color: colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.of(ctx).pop(opt),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          actions: [
            TertiaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
              expand: false,
              height: 40,
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
    final onSurface = theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return ListTile(
      leading: leading,
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
            )
          : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
