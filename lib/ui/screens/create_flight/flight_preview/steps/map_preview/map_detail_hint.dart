import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class MapDetailHint extends StatelessWidget {
  const MapDetailHint({
    required this.message,
    required this.details,
    required this.highlighted,
    super.key,
  });

  final String message;
  final String details;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final premiumAccent = DsPremiumColors.accent(context);
    final primaryTextColor = highlighted
        ? premiumAccent
        : colorScheme.onSurface;
    final secondaryTextColor = highlighted
        ? premiumAccent.withValues(alpha: 0.82)
        : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? DsPremiumColors.subtleSurface(context)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? DsPremiumColors.border(context)
              : colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            maxLines: 1,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            maxLines: 1,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
