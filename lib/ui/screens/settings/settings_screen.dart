import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flymap/router/app_router.dart';

import 'widgets/leave_feedback_setting_item.dart';
import 'widgets/rate_us_setting_item.dart';
import 'widgets/subscription_top_banner.dart';
import 'widgets/units_setting_item.dart';
import 'viewmodel/settings_cubit.dart';
import 'viewmodel/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(context.t.settings.title)],
        ),
      ),
      body: const SettingsContent(),
    );
  }
}

class SettingsContent extends StatelessWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, subscriptionState) {
        return BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (state.isLoading) {
              return LoadingStateView(title: context.t.settings.loading);
            }
            final theme = Theme.of(context);
            final sectionBg = theme.colorScheme.surfaceContainerHighest;
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: SubscriptionTopBanner(
                    state: subscriptionState,
                    onManage: () => _openSubscription(context),
                  ),
                ),
                // Appearance section
                Container(
                  width: double.infinity,
                  color: sectionBg,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    context.t.settings.appearance,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SettingItem(
                  title: context.t.settings.theme,
                  subtitle: state.themeMode == ThemeMode.dark
                      ? context.t.settings.dark
                      : context.t.settings.light,
                  leading: const Icon(Icons.dark_mode),
                  onTap: () async {
                    final darkLabel = context.t.settings.dark;
                    final lightLabel = context.t.settings.light;
                    final selected = await _showOptions(
                      context,
                      title: context.t.settings.theme,
                      options: [darkLabel, lightLabel],
                      current: state.themeMode == ThemeMode.dark
                          ? darkLabel
                          : lightLabel,
                    );
                    if (!context.mounted) return;
                    if (selected != null) {
                      context.read<SettingsCubit>().setTheme(
                        selected == darkLabel
                            ? ThemeMode.dark
                            : ThemeMode.light,
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
                    context.t.settings.units,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                UnitsSettingItem(state: state),

                // About section
                Container(
                  width: double.infinity,
                  color: sectionBg,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    context.t.settings.about,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _SettingItem(
                  title: context.t.settings.about,
                  subtitle: context.t.settings.aboutSubtitle,
                  leading: const Icon(Icons.info_outline),
                  onTap: () {
                    AppRouter.goToAbout(context);
                  },
                ),
                const Divider(height: 1),
                _SettingItem(
                  title: context.t.settings.privacyPolicy,
                  subtitle: context.t.settings.privacyPolicySubtitle,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  onTap: () async {
                    await _openExternalUrl(
                      context,
                      'https://www.apptractor.dev/projects/flymap/privacy',
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingItem(
                  title: context.t.settings.termsOfService,
                  subtitle: context.t.settings.termsOfServiceSubtitle,
                  leading: const Icon(Icons.description_outlined),
                  onTap: () async {
                    await _openExternalUrl(
                      context,
                      'https://www.apptractor.dev/projects/flymap/terms',
                    );
                  },
                ),
                const Divider(height: 1),
                const LeaveFeedbackSettingItem(),
                const Divider(height: 1),
                const RateUsSettingItem(),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSubscription(BuildContext context) async {
    final subscriptionCubit = context.read<SubscriptionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    if (subscriptionCubit.state.isPro) {
      AppRouter.goToSubscriptionManagement(context);
      return;
    }

    final result = await subscriptionCubit.presentPaywallFromSettings();
    if (!context.mounted) return;

    switch (result) {
      case SubscriptionPaywallResult.purchased:
      case SubscriptionPaywallResult.restored:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.flymapProActivated)),
        );
        AppRouter.goToSubscriptionManagement(context);
        return;
      case SubscriptionPaywallResult.cancelled:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.upgradeCancelled)),
        );
        return;
      case SubscriptionPaywallResult.notPresented:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.noPaywall)),
        );
        return;
      case SubscriptionPaywallResult.error:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.failedOpenPaywall)),
        );
        return;
    }
  }

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.settings.couldNotOpenUrl(url: url))),
      );
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
              label: context.t.common.cancel,
              onPressed: () => Navigator.of(ctx).pop(),
              expand: false,
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
