import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';
import '../route_type_selector_screen.dart';

class RouteTypeCard extends StatelessWidget {
  final RouteType type;
  final String title;
  final String subtitle;
  final String description;
  final bool isSelected;
  final bool isProOnly;
  final VoidCallback onTap;

  const RouteTypeCard({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.isProOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final imagePath = type == RouteType.basic
        ? (isDark
              ? 'assets/images/route_approximate_dark.webp'
              : 'assets/images/route_approximate_light.webp')
        : (isDark
              ? 'assets/images/route_historical_dark.webp'
              : 'assets/images/route_historical_light.webp');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DsRadii.lg),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(DsSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DsRadii.lg),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: 2,
              ),
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.05)
                  : colorScheme.surface,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DsRadii.md),
                  child: Image.asset(
                    imagePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: DsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.body18Regular.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: DsSpacing.xxs),
                      Text(
                        subtitle,
                        style: context.textTheme.body16Medium.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: DsSpacing.sm),
                      Text(
                        description,
                        style: context.textTheme.caption14Regular.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                Opacity(
                  opacity: isSelected ? 1 : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: DsSpacing.sm),
                    child: Icon(Icons.check_circle, color: colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
          if (isProOnly)
            Positioned(
              bottom: -12,
              right: 24,
              child: Row(
                children: [
                  _chipLabel(
                    context,
                    context.t.createFlight.routeTypeSelector.mostAccurate,
                  ),
                  const SizedBox(width: 8),
                  _chipLabel(
                    context,
                    context.t.common.pro,
                    icon: Icons.workspace_premium_rounded,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chipLabel(BuildContext context, String text, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DsPremiumColors.goldFill, DsPremiumColors.goldHighlight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DsRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, color: DsPremiumColors.onGold, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: context.textTheme.caption14Regular.copyWith(
              color: DsPremiumColors.onGold,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
