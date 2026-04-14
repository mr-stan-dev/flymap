import 'package:flutter/material.dart';

class SettingsChoiceSection extends StatelessWidget {
  const SettingsChoiceSection({
    required this.options,
    required this.current,
    required this.onChanged,
    this.title,
    super.key,
  });

  final String? title;
  final List<String> options;
  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == current;
            return ChoiceChip(
              label: Text(
                option,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              backgroundColor: colorScheme.surfaceContainerHighest,
              selectedColor: colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.24),
              ),
              showCheckmark: false,
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}
