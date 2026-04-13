import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';

enum ProBadgeVariant { amber, premiumBlueStripes }

class ProBadge extends StatelessWidget {
  const ProBadge({
    this.label = 'PRO',
    this.compact = false,
    this.variant = ProBadgeVariant.amber,
    super.key,
  });

  final String label;
  final bool compact;
  final ProBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? 8 : 10,
      vertical: compact ? 3 : 4,
    );
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.35,
    );
    final borderRadius = BorderRadius.circular(999);

    if (variant == ProBadgeVariant.premiumBlueStripes) {
      final isLightTheme = Theme.of(context).brightness == Brightness.light;
      final gradientColors = PremiumSurfaceGradients.free(
        isLightTheme: isLightTheme,
      );
      return ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: PremiumDiagonalStripesOverlay(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              Padding(
                padding: padding,
                child: Text(label, style: textStyle),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DsBrandColors.proAmber,
        borderRadius: borderRadius,
      ),
      child: Text(
        label,
        style: textStyle?.copyWith(color: DsBrandColors.onProAmber),
      ),
    );
  }
}

class ProGradientStrip extends StatelessWidget {
  const ProGradientStrip({this.height = 4, this.borderRadius, super.key});

  final double height;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            DsBrandColors.proAmber.withValues(alpha: 0.08),
            DsBrandColors.proAmber.withValues(alpha: 0.45),
            DsBrandColors.proAmber.withValues(alpha: 0.08),
          ],
        ),
      ),
    );
  }
}

class ProActiveBlock extends StatelessWidget {
  const ProActiveBlock({
    required this.title,
    required this.message,
    this.icon = Icons.workspace_premium_rounded,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DsBrandColors.proAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
            child: ProGradientStrip(height: 3),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: DsBrandColors.proAmber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: DsBrandColors.proAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
