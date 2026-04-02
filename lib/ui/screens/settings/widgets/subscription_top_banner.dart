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
    final state = this.state;
    final isPro = state.isPro;
    final isLightTheme = Theme.of(context).brightness == Brightness.light;
    final cardRadius = BorderRadius.circular(DsRadii.xl);
    final title = isPro
        ? context.t.settings.proBannerTitleActive
        : context.t.settings.proBannerTitle;
    final subtitle = switch (state.phase) {
      SubscriptionPhase.unknown ||
      SubscriptionPhase.loading => context.t.subscription.checkingStatus,
      SubscriptionPhase.pro => context.t.settings.proBannerSubtitleActive,
      SubscriptionPhase.free => context.t.settings.proBannerSubtitleFree,
    };
    final badgeLabel = isPro
        ? context.t.settings.proBannerBadgeActive
        : context.t.common.upgrade.toUpperCase();
    final gradientColors = isPro
        ? PremiumSurfaceGradients.pro(isLightTheme: isLightTheme)
        : PremiumSurfaceGradients.free(isLightTheme: isLightTheme);

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
                    color: isPro
                        ? DsBrandColors.proAmber.withValues(alpha: 0.65)
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            Positioned.fill(child: PremiumDiagonalStripesOverlay()),
            Positioned(
              right: -18,
              top: -26,
              child: Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white.withValues(alpha: 0.1),
                size: 124,
              ),
            ),
            Positioned.fill(
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
                        _BannerBadge(label: badgeLabel),
                        const SizedBox(height: DsSpacing.sm),
                        Text(
                          title,
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
