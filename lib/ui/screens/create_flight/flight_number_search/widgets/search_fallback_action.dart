import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

/// Error / empty-state block for the flight search flows: icon, message, a
/// primary recovery action, and an optional secondary route out.
class SearchFallbackAction extends StatelessWidget {
  const SearchFallbackAction({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    this.title,
    this.icon,
    this.secondaryActionLabel,
    this.onSecondaryPressed,
    super.key,
  });

  final String? title;
  final String message;
  final IconData? icon;
  final String actionLabel;
  final VoidCallback onPressed;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 44,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
        ],
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: actionLabel,
          onPressed: onPressed,
          expand: false,
        ),
        if (secondaryActionLabel != null && onSecondaryPressed != null) ...[
          const SizedBox(height: 4),
          TertiaryButton(
            label: secondaryActionLabel!,
            onPressed: onSecondaryPressed,
            expand: false,
          ),
        ],
      ],
    );
  }
}
