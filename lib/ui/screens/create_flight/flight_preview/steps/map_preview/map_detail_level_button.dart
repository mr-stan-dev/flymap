import 'package:flutter/material.dart';

class MapDetailLevelButton extends StatelessWidget {
  const MapDetailLevelButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.selectedBorderColor,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final Color? selectedBorderColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor =
        selectedBorderColor ?? Theme.of(context).colorScheme.primary;
    final effectiveBorderColor = selected
        ? borderColor
        : colorScheme.outline.withValues(alpha: 0.35);
    final contentColor = selected ? borderColor : colorScheme.onSurface;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: effectiveBorderColor, width: 1.5),
        ),
        onPressed: onPressed,
        child: _MapDetailLevelButtonContent(
          label: label,
          icon: icon,
          color: contentColor,
        ),
      ),
    );
  }
}

class _MapDetailLevelButtonContent extends StatelessWidget {
  const _MapDetailLevelButtonContent({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
