import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      appBar: AppBar(title: const Text('Subscription')),
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
                    'Pull down to refresh your subscription status.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SectionCard(
                    title: 'Need help?',
                    child: SecondaryButton(
                      label: 'Contact support',
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
      SubscriptionPhase.loading => 'Checking your subscription status...',
      SubscriptionPhase.pro => 'Flymap Pro is active.',
      SubscriptionPhase.free => 'You are on Free plan.',
    };

    return SectionCard(
      title: 'Flymap Pro',
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
            label: 'Status',
            value: state.isPro ? 'Active' : 'Not active',
          ),
          _MetaRow(
            label: 'Entitlement',
            value: state.status?.entitlementId ?? 'Flymap Pro',
          ),
          _MetaRow(
            label: 'Expires',
            value: _formatDateTime(state.status?.expiresAt) ?? 'No expiration',
          ),
          _MetaRow(
            label: 'Last update',
            value: _formatDateTime(state.lastUpdatedAt) ?? 'Unknown',
          ),
          const SizedBox(height: 8),
          if (state.isPro)
            TertiaryButton(
              label: 'Manage subscription',
              leadingIcon: Icons.storefront_rounded,
              trailingIcon: Icons.open_in_new_rounded,
              onPressed: () => _openStoreSubscriptions(
                messenger: ScaffoldMessenger.of(context),
                platform: Theme.of(context).platform,
              ),
            )
          else
            PremiumButton(
              label: 'Upgrade to Pro',
              onPressed: _isPaywallLoading ? null : () => _openPaywall(context),
              isLoading: _isPaywallLoading,
            ),
          const SizedBox(height: 8),
          Text(
            state.isPro
                ? 'You can cancel or change billing in your App Store or Google Play subscription settings.'
                : 'Free users can upgrade to Pro to unlock premium features.',
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
      queryParameters: const {'subject': 'Flymap subscription support'},
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open email app')));
    }
  }

  Future<void> _openStoreSubscriptions({
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
        const SnackBar(content: Text('Could not open subscription settings')),
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
        SubscriptionPaywallResult.purchased => 'Flymap Pro activated.',
        SubscriptionPaywallResult.restored => 'Flymap Pro restored.',
        SubscriptionPaywallResult.cancelled => 'Upgrade cancelled.',
        SubscriptionPaywallResult.notPresented =>
          'No paywall available right now.',
        SubscriptionPaywallResult.error => 'Failed to open paywall.',
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
