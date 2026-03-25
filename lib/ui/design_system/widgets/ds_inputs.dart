import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/tokens/ds_radii.dart';
import 'package:flymap/ui/design_system/tokens/ds_semantic_colors.dart';

class SearchInputField extends StatelessWidget {
  const SearchInputField({
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.isSelected = false,
    this.onClear,
    this.suffixActions = const [],
    this.selectedBorderColor,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool isSelected;
  final VoidCallback? onClear;
  final List<Widget> suffixActions;
  final Color? selectedBorderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor =
        selectedBorderColor ?? DsSemanticColors.success(context);
    final normalBorderColor = theme.colorScheme.outline.withValues(alpha: 0.45);
    final iconColor = isSelected
        ? selectedColor
        : theme.colorScheme.onSurfaceVariant;

    final suffix = suffixActions.isNotEmpty
        ? Row(mainAxisSize: MainAxisSize.min, children: suffixActions)
        : (controller.text.isNotEmpty && onClear != null)
        ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
        : null;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search, color: iconColor),
        suffixIcon: suffix,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: hintText,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadii.md),
          borderSide: BorderSide(
            color: isSelected ? selectedColor : normalBorderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadii.md),
          borderSide: BorderSide(
            color: isSelected ? selectedColor : theme.colorScheme.primary,
            width: isSelected ? 2.4 : 1.8,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DsRadii.md),
        ),
      ),
    );
  }
}
