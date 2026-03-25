import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/tokens/ds_radii.dart';
import 'package:flymap/ui/design_system/tokens/ds_semantic_colors.dart';

enum StatusChipTone { success, warning, error, info, neutral }

class SelectionChip extends StatelessWidget {
  const SelectionChip({
    required this.label,
    required this.onPressed,
    this.leading,
    this.onDeleted,
    this.deleteIcon,
    this.deleteTooltip,
    this.selected = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final VoidCallback? onDeleted;
  final Widget? deleteIcon;
  final String? deleteTooltip;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      selected: selected,
      avatar: leading,
      onPressed: onPressed,
      onDeleted: onDeleted,
      deleteIcon: deleteIcon,
      deleteButtonTooltipMessage: deleteTooltip,
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.tone = StatusChipTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final StatusChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DsRadii.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(BuildContext context, StatusChipTone tone) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (tone) {
      case StatusChipTone.success:
        return DsSemanticColors.success(context);
      case StatusChipTone.warning:
        return DsSemanticColors.warning(context);
      case StatusChipTone.error:
        return DsSemanticColors.error(context);
      case StatusChipTone.info:
        return DsSemanticColors.info(context);
      case StatusChipTone.neutral:
        return colorScheme.onSurfaceVariant;
    }
  }
}

class MetaPill extends StatelessWidget {
  const MetaPill({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(DsRadii.sm),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
