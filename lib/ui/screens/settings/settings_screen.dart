import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
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
      body: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, subscriptionState) {
          return BlocBuilder<SettingsCubit, SettingsState>(
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
                    subtitle: state.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : 'Light',
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

                  // Subscription section
                  Container(
                    width: double.infinity,
                    color: sectionBg,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Text(
                      'Subscription',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _SettingItem(
                    title: 'Flymap Pro',
                    subtitle: _subscriptionStatusText(subscriptionState),
                    leading: const Icon(Icons.workspace_premium_outlined),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _SettingItem(
                    title: 'Open Paywall',
                    subtitle: 'Weekly / monthly / yearly plans',
                    leading: const Icon(Icons.local_offer_outlined),
                    onTap: () => _openPaywall(context),
                  ),
                  const Divider(height: 1),
                  _SettingItem(
                    title: 'Restore Purchases',
                    subtitle: 'Recover previous subscriptions',
                    leading: const Icon(Icons.restore),
                    onTap: () => _restorePurchases(context),
                  ),
                  const Divider(height: 1),
                  _SettingItem(
                    title: 'Manage Subscription',
                    subtitle: 'Open RevenueCat Customer Center',
                    leading: const Icon(Icons.manage_accounts_outlined),
                    onTap: () => _openCustomerCenter(context),
                  ),
                  if (subscriptionState.isProductsLoading) ...[
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ] else if (subscriptionState.products.isNotEmpty) ...[
                    const Divider(height: 1),
                    ...subscriptionState.products.map((product) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.sell_outlined),
                            title: Text(product.title),
                            subtitle: Text(
                              product.description.trim().isEmpty
                                  ? product.productId
                                  : product.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(product.priceText),
                            onTap: () => _purchasePackage(
                              context,
                              packageId: product.packageId,
                              label: product.title,
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }),
                  ],

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
                        'https://www.apptractor.dev/projects/flymap/privacy',
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  String _subscriptionStatusText(SubscriptionState state) {
    if (state.phase == SubscriptionPhase.loading ||
        state.phase == SubscriptionPhase.unknown) {
      return 'Checking subscription status...';
    }

    if (state.isPro) {
      return 'Active';
    }

    return state.errorMessage?.trim().isNotEmpty == true
        ? 'Not active (${state.errorMessage})'
        : 'Not active';
  }

  Future<void> _openPaywall(BuildContext context) async {
    final result = await context
        .read<SubscriptionCubit>()
        .presentPaywallIfNeeded();
    if (!context.mounted) return;

    final message = switch (result) {
      SubscriptionPaywallResult.purchased => 'Purchase completed successfully.',
      SubscriptionPaywallResult.restored => 'Purchases restored successfully.',
      SubscriptionPaywallResult.cancelled => 'Purchase cancelled.',
      SubscriptionPaywallResult.notPresented => 'You already have access.',
      SubscriptionPaywallResult.error => 'Failed to open paywall.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restorePurchases(BuildContext context) async {
    await context.read<SubscriptionCubit>().restorePurchases();
    if (!context.mounted) return;
    final state = context.read<SubscriptionCubit>().state;
    final message = state.errorMessage?.trim().isNotEmpty == true
        ? state.errorMessage!
        : 'Restore completed.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCustomerCenter(BuildContext context) async {
    await context.read<SubscriptionCubit>().presentCustomerCenter();
  }

  Future<void> _purchasePackage(
    BuildContext context, {
    required String packageId,
    required String label,
  }) async {
    await context.read<SubscriptionCubit>().purchasePackage(packageId);
    if (!context.mounted) return;
    final state = context.read<SubscriptionCubit>().state;
    final message = state.isPro
        ? '$label purchased successfully.'
        : (state.errorMessage?.trim().isNotEmpty == true
              ? state.errorMessage!
              : 'Purchase did not complete.');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
