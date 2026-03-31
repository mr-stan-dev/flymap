import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<SubscriptionCubit>();
      unawaited(cubit.refresh());
      if (cubit.state.products.isEmpty && !cubit.state.isProductsLoading) {
        unawaited(cubit.loadProducts());
      }
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

            if (!state.isPro) {
              return _buildFreePaywallOnly(context, state);
            }

            return RefreshIndicator(
              onRefresh: () async {
                final cubit = context.read<SubscriptionCubit>();
                await cubit.refresh();
                await cubit.loadProducts();
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatusCard(context, state),
                  const SizedBox(height: 12),
                  _buildActionsCard(context, state),
                  const SizedBox(height: 12),
                  _buildPlansCard(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFreePaywallOnly(BuildContext context, SubscriptionState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Flymap Pro',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InfoBanner(
                message: 'Unlock Flymap Pro to get premium features.',
                tone: DsMessageTone.info,
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'See Pro Plans',
                leadingIcon: Icons.workspace_premium_outlined,
                onPressed: () => _openPaywall(context),
              ),
              if (state.errorMessage?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                InlineMessage(
                  message: state.errorMessage!,
                  tone: DsMessageTone.warning,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, SubscriptionState state) {
    final statusText = switch (state.phase) {
      SubscriptionPhase.unknown ||
      SubscriptionPhase.loading => 'Checking your subscription status...',
      SubscriptionPhase.pro => 'Flymap Pro is active.',
      SubscriptionPhase.free => 'You are on Free plan.',
    };

    final tone = switch (state.phase) {
      SubscriptionPhase.pro => DsMessageTone.success,
      SubscriptionPhase.free => DsMessageTone.neutral,
      SubscriptionPhase.unknown ||
      SubscriptionPhase.loading => DsMessageTone.info,
    };

    return SectionCard(
      title: 'Flymap Pro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoBanner(message: statusText, tone: tone),
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

  Widget _buildActionsCard(BuildContext context, SubscriptionState state) {
    final isBusy = state.isLoading;
    return SectionCard(
      title: 'Manage',
      child: Column(
        children: [
          PrimaryButton(
            label: 'Open Paywall',
            leadingIcon: Icons.local_offer_outlined,
            isLoading: isBusy,
            onPressed: isBusy ? null : () => _openPaywall(context),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Restore Purchases',
            leadingIcon: Icons.restore,
            onPressed: isBusy ? null : () => _restorePurchases(context),
          ),
          const SizedBox(height: 8),
          TertiaryButton(
            label: 'Customer Center',
            leadingIcon: Icons.manage_accounts_outlined,
            onPressed: isBusy ? null : () => _openCustomerCenter(context),
          ),
          const SizedBox(height: 8),
          TertiaryButton(
            label: 'Refresh Status',
            leadingIcon: Icons.refresh,
            onPressed: isBusy
                ? null
                : () => context.read<SubscriptionCubit>().refresh(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansCard(BuildContext context, SubscriptionState state) {
    if (state.isProductsLoading) {
      return const SectionCard(
        title: 'Available Plans',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state.products.isEmpty) {
      return SectionCard(
        title: 'Available Plans',
        trailing: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<SubscriptionCubit>().loadProducts(),
        ),
        child: const Text(
          'No plans available right now. Pull down to refresh.',
        ),
      );
    }

    return SectionCard(
      title: 'Available Plans',
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => context.read<SubscriptionCubit>().loadProducts(),
      ),
      child: Column(
        children: state.products
            .map(
              (product) => _PlanTile(
                product: product,
                onTap: () => _purchasePackage(
                  context,
                  packageId: product.packageId,
                  label: product.title,
                ),
              ),
            )
            .toList(),
      ),
    );
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
    _showMessage(context, message);
  }

  Future<void> _restorePurchases(BuildContext context) async {
    await context.read<SubscriptionCubit>().restorePurchases();
    if (!context.mounted) return;
    final state = context.read<SubscriptionCubit>().state;
    final message = state.errorMessage?.trim().isNotEmpty == true
        ? state.errorMessage!
        : 'Restore completed.';
    _showMessage(context, message);
  }

  Future<void> _openCustomerCenter(BuildContext context) async {
    await context.read<SubscriptionCubit>().presentCustomerCenter();
    if (!context.mounted) return;
    final state = context.read<SubscriptionCubit>().state;
    if (state.errorMessage?.trim().isNotEmpty == true) {
      _showMessage(context, state.errorMessage!);
    }
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
    _showMessage(context, message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.product, required this.onTap});

  final SubscriptionProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
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
      onTap: onTap,
    );
  }
}
