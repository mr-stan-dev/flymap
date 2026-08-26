import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/tokens/ds_brand_colors.dart';
import 'package:flymap/ui/widgets/premium_surface_effects.dart';

enum ProBadgeVariant { amber, premiumNavy }

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
    final baseTextStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.35,
    );
    final borderRadius = BorderRadius.circular(999);

    if (variant == ProBadgeVariant.premiumNavy) {
      final isLightTheme = Theme.of(context).brightness == Brightness.light;
      final gradientColors = PremiumSurfaceGradients.pro(
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
                child: Text(
                  label,
                  style: baseTextStyle?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: DsPremiumColors.fill(context),
        borderRadius: borderRadius,
      ),
      child: Text(
        label,
        style: baseTextStyle?.copyWith(
          color: DsPremiumColors.foreground(context),
        ),
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
    final accent = DsPremiumColors.accent(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accent.withValues(alpha: 0.08),
            accent.withValues(alpha: 0.55),
            accent.withValues(alpha: 0.08),
          ],
        ),
      ),
    );
  }
}

class ProAppBarInfoButton extends StatelessWidget {
  const ProAppBarInfoButton({
    required this.title,
    required this.message,
    required this.tooltip,
    super.key,
  });

  final String title;
  final String message;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () => _showDialog(context),
      icon: Icon(
        Icons.workspace_premium_rounded,
        color: DsPremiumColors.accent(context),
      ),
    );
  }

  Future<void> _showDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: MaterialLocalizations.of(context).okButtonLabel.isEmpty
                ? Text(context.t.common.ok)
                : Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
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
    final accent = DsPremiumColors.accent(context);
    return Container(
      decoration: BoxDecoration(
        color: DsPremiumColors.subtleSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DsPremiumColors.border(context)),
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
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: accent,
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
