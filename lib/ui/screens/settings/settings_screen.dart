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
import 'widgets/setting_item.dart';
import 'widgets/settings_group_card.dart';
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                SubscriptionTopBanner(
                  state: subscriptionState,
                  onManage: () => _openSubscription(context),
                ),
                const SizedBox(height: 12),
                SettingsGroupCard(
                  title: context.t.settings.appearance,
                  children: [
                    SettingItem(
                      title: context.t.settings.theme,
                      subtitle: _themeModeLabel(context, state.themeMode),
                      leading: const Icon(Icons.dark_mode),
                      onTap: () async {
                        final systemLabel = context.t.settings.system;
                        final darkLabel = context.t.settings.dark;
                        final lightLabel = context.t.settings.light;
                        final selected = await _showOptions(
                          context,
                          title: context.t.settings.theme,
                          options: [systemLabel, darkLabel, lightLabel],
                          current: _themeModeLabel(context, state.themeMode),
                        );
                        if (!context.mounted) return;
                        if (selected != null) {
                          context.read<SettingsCubit>().setTheme(
                            switch (selected) {
                              final value when value == darkLabel =>
                                ThemeMode.dark,
                              final value when value == lightLabel =>
                                ThemeMode.light,
                              _ => ThemeMode.system,
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsGroupCard(
                  title: context.t.settings.units,
                  children: [UnitsSettingItem(state: state)],
                ),
                const SizedBox(height: 12),
                SettingsGroupCard(
                  title: context.t.settings.support,
                  children: [
                    const LeaveFeedbackSettingItem(),
                    const RateUsSettingItem(),
                  ],
                ),
                const SizedBox(height: 12),
                SettingsGroupCard(
                  title: context.t.settings.about,
                  children: [
                    SettingItem(
                      title: context.t.settings.about,
                      subtitle: context.t.settings.aboutSubtitle,
                      leading: const Icon(Icons.info_outline),
                      onTap: () {
                        AppRouter.goToAbout(context);
                      },
                    ),
                    SettingItem(
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
                    SettingItem(
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
                  ],
                ),
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

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    return switch (mode) {
      ThemeMode.dark => context.t.settings.dark,
      ThemeMode.light => context.t.settings.light,
      ThemeMode.system => context.t.settings.system,
    };
  }
}
