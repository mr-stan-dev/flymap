import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';

class SubscriptionTopBanner extends StatelessWidget {
  const SubscriptionTopBanner({
    required this.state,
    required this.onManage,
    super.key,
  });

  final SubscriptionState state;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    return state.isPro
        ? _SubscribedBanner(state: state, onManage: onManage)
        : _UpgradeBanner(state: state, onManage: onManage);
  }
}

class _BannerBadge extends StatelessWidget {
  const _BannerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(DsRadii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.35,
        ),
      ),
    );
  }
}

class _UpgradeBanner extends StatelessWidget {
  const _UpgradeBanner({required this.state, required this.onManage});

  final SubscriptionState state;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final cardRadius = BorderRadius.circular(DsRadii.xl);
    final subtitle = switch (state.phase) {
      SubscriptionPhase.unknown ||
      SubscriptionPhase.loading => context.t.subscription.checkingStatus,
      SubscriptionPhase.pro => context.t.settings.proBannerSubtitleActive,
      SubscriptionPhase.free => context.t.settings.proBannerSubtitleFree,
    };
    final gradientColors = PremiumSurfaceGradients.free(
      isLightTheme: isLightTheme,
    );

    return GestureDetector(
      onTap: onManage,
      child: ClipRRect(
        borderRadius: cardRadius,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: cardRadius,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: PremiumDiagonalStripesOverlay()),
            Positioned(
              right: -18,
              top: -26,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white.withValues(alpha: 0.1),
                size: 124,
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: PremiumAnimatedShimmerOverlay()),
            ),
            Padding(
              padding: const EdgeInsets.all(DsSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BannerBadge(
                          label: context.t.common.upgrade.toUpperCase(),
                        ),
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          context.t.settings.proBannerTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DsSpacing.sm),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.32),
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribedBanner extends StatelessWidget {
  const _SubscribedBanner({required this.state, required this.onManage});

  final SubscriptionState state;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cardRadius = BorderRadius.circular(DsRadii.xl);
    final gradientColors = [
      colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      DsBrandColors.proAmber.withValues(
        alpha: theme.brightness == Brightness.light ? 0.16 : 0.22,
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onManage,
        borderRadius: cardRadius,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: DsBrandColors.proAmber.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.md,
              vertical: DsSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DsBrandColors.proAmber.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: DsBrandColors.proAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: Text(
                    context.t.settings.proBannerTitleActive,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpacing.sm,
                    vertical: DsSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(DsRadii.pill),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    context.t.common.manage,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
