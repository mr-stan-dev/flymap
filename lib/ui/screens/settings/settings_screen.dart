import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flymap/router/app_router.dart';

import 'widgets/app_version_footer.dart';
import 'widgets/leave_feedback_setting_item.dart';
import 'widgets/rate_us_setting_item.dart';
import 'widgets/setting_item.dart';
import 'widgets/settings_group_card.dart';
import 'widgets/subscription_top_banner.dart';
import 'widgets/theme_setting_item.dart';
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
                  children: [ThemeSettingItem(state: state)],
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
                      leading: const Icon(Icons.info_outline),
                      onTap: () {
                        AppRouter.goToAbout(context);
                      },
                    ),
                    SettingItem(
                      title: context.t.settings.privacyPolicy,
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
                const AppVersionFooter(),
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
}
