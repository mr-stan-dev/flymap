import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() =>
      _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState
    extends State<SubscriptionManagementScreen> {
  static const String _supportEmail = 'team@apptractor.dev';
  static final Uri _iosSubscriptionsUri = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );
  static final Uri _androidSubscriptionsUri = Uri.parse(
    'https://play.google.com/store/account/subscriptions',
  );

  bool _isPaywallLoading = false;
  bool _isRestoreLoading = false;
  bool _isSubscriptionSettingsLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<SubscriptionCubit>().refresh());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.subscription.screenTitle)),
      body: SafeArea(
        child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, state) {
            final isInitialLoading =
                (state.phase == SubscriptionPhase.unknown ||
                    state.phase == SubscriptionPhase.loading) &&
                state.status == null;
            if (isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final isPro = _isProActive(state);
            return RefreshIndicator(
              onRefresh: context.read<SubscriptionCubit>().refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  DsSpacing.md,
                  DsSpacing.sm,
                  DsSpacing.md,
                  DsSpacing.xl,
                ),
                children: [
                  if (isPro)
                    _ProMembershipHero(
                      formattedDate: _formatDate(
                        context,
                        state.status?.expiresAt,
                      ),
                    )
                  else
                    _buildFreeStatusCard(context),
                  if (state.errorMessage?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: DsSpacing.sm),
                    InlineMessage(
                      message: state.errorMessage!,
                      tone: DsMessageTone.warning,
                    ),
                  ],
                  const SizedBox(height: DsSpacing.md),
                  _buildProFeaturesCard(context, isPro: isPro),
                  if (state.unusedFlightUnlockCount > 0) ...[
                    const SizedBox(height: DsSpacing.md),
                    _buildFlightPassesCard(context, state),
                  ],
                  if (isPro) ...[
                    const SizedBox(height: DsSpacing.md),
                    _buildPlanAndBillingCard(context),
                  ],
                  const SizedBox(height: DsSpacing.md),
                  _buildPurchaseHelpCard(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isProActive(SubscriptionState state) {
    return state.isPro || state.status?.isPro == true;
  }

  String? _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return null;
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  Widget _buildFreeStatusCard(BuildContext context) {
    return SectionCard(
      title: context.t.subscription.cardTitle,
      trailing: StatusChip(
        label: context.t.subscription.notActive,
        tone: StatusChipTone.neutral,
        icon: Icons.lock_open_rounded,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t.subscription.freePlan,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          PremiumButton(
            label: context.t.subscription.upgradeToPro,
            onPressed: _isPaywallLoading ? null : () => _openPaywall(context),
            isLoading: _isPaywallLoading,
            trailingIcon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildProFeaturesCard(BuildContext context, {required bool isPro}) {
    final benefits = <_ProBenefit>[
      _ProBenefit(
        icon: Icons.route_rounded,
        title: context.t.subscription.proFeatureRoutesTitle,
        body: context.t.subscription.proFeatureRoutesBody,
      ),
      _ProBenefit(
        icon: Icons.map_rounded,
        title: context.t.subscription.proFeatureMapsTitle,
        body: context.t.subscription.proFeatureMapsBody,
      ),
      _ProBenefit(
        icon: Icons.travel_explore_rounded,
        title: context.t.subscription.proFeatureTimelineTitle,
        body: context.t.subscription.proFeatureTimelineBody,
      ),
      _ProBenefit(
        icon: Icons.cloud_rounded,
        title: context.t.subscription.proFeatureWeatherTitle,
        body: context.t.subscription.proFeatureWeatherBody,
      ),
      _ProBenefit(
        icon: Icons.quiz_rounded,
        title: context.t.subscription.proFeatureLearnTitle,
        body: context.t.subscription.proFeatureLearnBody,
      ),
    ];

    return SectionCard(
      title: isPro
          ? context.t.subscription.proFeaturesIncludedTitle
          : context.t.subscription.proFeaturesTitle,
      child: Column(
        children: [
          for (var index = 0; index < benefits.length; index++) ...[
            _ProFeatureRow(benefit: benefits[index], unlocked: isPro),
            if (index != benefits.length - 1)
              const SizedBox(height: DsSpacing.sm),
          ],
        ],
      ),
    );
  }

  Widget _buildFlightPassesCard(BuildContext context, SubscriptionState state) {
    return SectionCard(
      title: context.t.subscription.flightPassesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetaPill(
            icon: Icons.confirmation_number_rounded,
            text: context.t.subscription.flightUnlockAvailableCount(
              count: state.unusedFlightUnlockCount,
            ),
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            context.t.subscription.flightPassesBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanAndBillingCard(BuildContext context) {
    return SectionCard(
      title: context.t.subscription.planAndBillingTitle,
      child: Column(
        children: [
          _MetaRow(
            label: context.t.subscription.planLabel,
            value: context.t.subscription.cardTitle,
          ),
          const SizedBox(height: DsSpacing.md),
          SecondaryButton(
            label: context.t.subscription.managePlanAndBilling,
            leadingIcon: Icons.credit_card_rounded,
            trailingIcon: Icons.chevron_right_rounded,
            isLoading: _isSubscriptionSettingsLoading,
            onPressed: _isSubscriptionSettingsLoading
                ? null
                : () => _openStoreSubscriptions(context),
          ),
          const SizedBox(height: DsSpacing.xs),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DsRadii.md),
                ),
              ),
              onPressed: _isSubscriptionSettingsLoading
                  ? null
                  : () => _openStoreSubscriptions(context),
              icon: const Icon(Icons.cancel_outlined, size: 19),
              label: Text(context.t.subscription.cancelSubscription),
            ),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            context.t.subscription.cancellationHelper,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHelpCard(BuildContext context) {
    return SectionCard(
      title: context.t.subscription.purchaseHelpTitle,
      child: Column(
        children: [
          TertiaryButton(
            label: context.t.subscription.restorePurchases,
            leadingIcon: Icons.restore_rounded,
            compact: true,
            isLoading: _isRestoreLoading,
            onPressed:
                _isRestoreLoading ||
                    _isPaywallLoading ||
                    _isSubscriptionSettingsLoading
                ? null
                : () => _restorePurchases(context),
          ),
          TertiaryButton(
            label: context.t.subscription.contactSupport,
            leadingIcon: Icons.support_agent_rounded,
            compact: true,
            onPressed: _isSubscriptionSettingsLoading
                ? null
                : () => _contactSupport(context),
          ),
        ],
      ),
    );
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

  Future<void> _openStoreSubscriptions(BuildContext context) async {
    if (_isSubscriptionSettingsLoading) return;
    setState(() => _isSubscriptionSettingsLoading = true);
    final platform = Theme.of(context).platform;
    final uri = switch (platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => _iosSubscriptionsUri,
      TargetPlatform.android => _androidSubscriptionsUri,
      _ => _androidSubscriptionsUri,
    };
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.t.subscription.couldNotOpenSubscriptionSettings,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubscriptionSettingsLoading = false);
      }
    }
  }

  Future<void> _openPaywall(BuildContext context) async {
    if (_isPaywallLoading) return;
    setState(() => _isPaywallLoading = true);
    final cubit = context.read<SubscriptionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.t;
    try {
      final result = await cubit.presentPaywallFromSubscriptionManagement();
      if (!mounted) return;
      final message = switch (result) {
        SubscriptionPaywallResult.purchased =>
          strings.settings.flymapProActivated,
        SubscriptionPaywallResult.restored => strings.subscription.proRestored,
        SubscriptionPaywallResult.cancelled =>
          strings.settings.upgradeCancelled,
        SubscriptionPaywallResult.notPresented => strings.settings.noPaywall,
        SubscriptionPaywallResult.error =>
          strings.subscription.failedOpenPaywall,
      };
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isPaywallLoading = false);
      }
    }
  }

  Future<void> _restorePurchases(BuildContext context) async {
    if (_isRestoreLoading) return;
    setState(() => _isRestoreLoading = true);
    final cubit = context.read<SubscriptionCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.t;
    try {
      await cubit.restorePurchases();
      if (!mounted) return;
      final errorMessage = cubit.state.errorMessage?.trim();
      final message = errorMessage != null && errorMessage.isNotEmpty
          ? errorMessage
          : cubit.state.isPro
          ? strings.subscription.proRestored
          : strings.subscription.restoreNoSubscription;
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isRestoreLoading = false);
      }
    }
  }
}

class _ProMembershipHero extends StatelessWidget {
  const _ProMembershipHero({required this.formattedDate});

  final String? formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(DsRadii.xl);
    final isLightTheme = theme.brightness == Brightness.light;

    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: PremiumSurfaceGradients.pro(
                    isLightTheme: isLightTheme,
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: PremiumDiagonalStripesOverlay()),
          Positioned(
            right: -18,
            bottom: -28,
            child: Transform.rotate(
              angle: -0.34,
              child: Icon(
                Icons.flight_rounded,
                size: 154,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(child: PremiumAnimatedShimmerOverlay()),
          ),
          Padding(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.32),
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    _HeroStatusBadge(
                      label: context.t.subscription.active.toUpperCase(),
                      icon: Icons.check_circle_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: DsSpacing.lg),
                Text(
                  context.t.subscription.cardTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: DsSpacing.xxs),
                Text(
                  context.t.subscription.proHeroSubtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: DsSpacing.lg),
                Text(
                  formattedDate == null
                      ? context.t.subscription.activeSubscription
                      : context.t.subscription.currentPeriodEnds(
                          date: formattedDate!,
                        ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  const _HeroStatusBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(DsRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProBenefit {
  const _ProBenefit({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _ProFeatureRow extends StatelessWidget {
  const _ProFeatureRow({required this.benefit, required this.unlocked});

  final _ProBenefit benefit;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(DsSpacing.sm),
      decoration: BoxDecoration(
        color: DsBrandColors.proAmber.withValues(
          alpha: theme.brightness == Brightness.light ? 0.07 : 0.12,
        ),
        borderRadius: BorderRadius.circular(DsRadii.md),
        border: Border.all(
          color: DsBrandColors.proAmber.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DsBrandColors.proAmber.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(benefit.icon, color: DsBrandColors.proAmber, size: 19),
          ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DsSpacing.xs),
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: unlocked
                ? DsSemanticColors.success(context)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: DsSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
