import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  static const String _supportEmail = 'support@apptractor.dev';
  static final Uri _iosSubscriptionsUri = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );
  static final Uri _androidSubscriptionsUri = Uri.parse(
    'https://play.google.com/store/account/subscriptions',
  );
  bool _isPaywallLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<SubscriptionCubit>();
      unawaited(cubit.refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.subscription.screenTitle)),
      body: SafeArea(
        child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, state) {
            if (state.phase == SubscriptionPhase.unknown ||
                state.phase == SubscriptionPhase.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: () async {
                final cubit = context.read<SubscriptionCubit>();
                await cubit.refresh();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(context, state),
                  const SizedBox(height: 8),
                  Text(
                    context.t.subscription.pullToRefresh,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: context.t.subscription.needHelp,
                    child: SecondaryButton(
                      label: context.t.subscription.contactSupport,
                      leadingIcon: Icons.support_agent_rounded,
                      onPressed: () => _contactSupport(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionState state) {
    final statusText = switch (state.phase) {
      SubscriptionPhase.unknown ||
      SubscriptionPhase.loading => context.t.subscription.checkingStatus,
      SubscriptionPhase.pro => context.t.subscription.proActive,
      SubscriptionPhase.free => context.t.subscription.freePlan,
    };

    return SectionCard(
      title: context.t.subscription.cardTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          state.isPro
              ? _buildProStatusBanner(context, statusText)
              : InfoBanner(
                  message: statusText,
                  tone: state.phase == SubscriptionPhase.free
                      ? DsMessageTone.neutral
                      : DsMessageTone.info,
                ),
          const SizedBox(height: 12),
          _MetaRow(
            label: context.t.subscription.status,
            value: state.isPro
                ? context.t.subscription.active
                : context.t.subscription.notActive,
          ),
          _MetaRow(
            label: context.t.subscription.entitlement,
            value:
                state.status?.entitlementId ?? context.t.subscription.cardTitle,
          ),
          _MetaRow(
            label: context.t.subscription.expires,
            value:
                _formatDateTime(state.status?.expiresAt) ??
                context.t.subscription.noExpiration,
          ),
          _MetaRow(
            label: context.t.subscription.lastUpdate,
            value:
                _formatDateTime(state.lastUpdatedAt) ??
                context.t.subscription.unknown,
          ),
          const SizedBox(height: 8),
          if (state.isPro)
            TertiaryButton(
              label: context.t.subscription.manageSubscription,
              leadingIcon: Icons.storefront_rounded,
              trailingIcon: Icons.open_in_new_rounded,
              onPressed: () => _openStoreSubscriptions(
                context: context,
                messenger: ScaffoldMessenger.of(context),
                platform: Theme.of(context).platform,
              ),
            )
          else
            PremiumButton(
              label: context.t.subscription.upgradeToPro,
              onPressed: _isPaywallLoading ? null : () => _openPaywall(context),
              isLoading: _isPaywallLoading,
            ),
          const SizedBox(height: 8),
          Text(
            state.isPro
                ? context.t.subscription.proManageHint
                : context.t.subscription.freeUpgradeHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (state.errorMessage?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            InlineMessage(
              message: state.errorMessage!,
              tone: DsMessageTone.warning,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProStatusBanner(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: DsBrandColors.proAmber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DsBrandColors.proAmber.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 18,
            color: DsBrandColors.proAmber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: DsBrandColors.proAmber,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDateTime(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    final yyyy = local.year.toString().padLeft(4, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': context.t.subscription.supportEmailSubject},
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.subscription.couldNotOpenEmailApp)),
      );
    }
  }

  Future<void> _openStoreSubscriptions({
    required BuildContext context,
    required ScaffoldMessengerState messenger,
    required TargetPlatform platform,
  }) async {
    final uri = switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => _iosSubscriptionsUri,
      TargetPlatform.android => _androidSubscriptionsUri,
      _ => _androidSubscriptionsUri,
    };
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            context.t.subscription.couldNotOpenSubscriptionSettings,
          ),
        ),
      );
    }
  }

  Future<void> _openPaywall(BuildContext context) async {
    if (_isPaywallLoading) return;
    setState(() => _isPaywallLoading = true);
    final cubit = context.read<SubscriptionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await cubit.presentPaywallIfNeeded();
      final message = switch (result) {
        SubscriptionPaywallResult.purchased =>
          context.t.settings.flymapProActivated,
        SubscriptionPaywallResult.restored =>
          context.t.subscription.proRestored,
        SubscriptionPaywallResult.cancelled =>
          context.t.settings.upgradeCancelled,
        SubscriptionPaywallResult.notPresented => context.t.settings.noPaywall,
        SubscriptionPaywallResult.error =>
          context.t.subscription.failedOpenPaywall,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isPaywallLoading = false);
      }
    }
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
