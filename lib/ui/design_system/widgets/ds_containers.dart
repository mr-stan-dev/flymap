import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/tokens/ds_radii.dart';
import 'package:flymap/ui/design_system/tokens/ds_semantic_colors.dart';
import 'package:flymap/ui/design_system/tokens/ds_spacing.dart';

enum DsMessageTone { neutral, info, success, warning, error }

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(DsSpacing.md),
    super.key,
  });

  final String? title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class ExpandableSectionCard extends StatelessWidget {
  const ExpandableSectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.initiallyExpanded = true,
    this.childrenPadding = const EdgeInsets.fromLTRB(
      DsSpacing.md,
      0,
      DsSpacing.md,
      DsSpacing.md,
    ),
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry childrenPadding;

  @override
  Widget build(BuildContext context) {
    final transparent = Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: 0);
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: transparent),
        child: ExpansionTile(
          title: Text(title),
          trailing: trailing,
          initiallyExpanded: initiallyExpanded,
          shape: const Border(),
          collapsedShape: const Border(),
          childrenPadding: childrenPadding,
          children: [child],
        ),
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.message,
    this.tone = DsMessageTone.info,
    this.icon,
    this.compact = false,
    super.key,
  });

  final String message;
  final DsMessageTone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DsSpacing.sm : DsSpacing.md,
        vertical: compact ? DsSpacing.xs : DsSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DsRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon ?? _defaultIcon(tone), size: 16, color: color),
          const SizedBox(width: DsSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _toneColor(BuildContext context, DsMessageTone tone) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (tone) {
      case DsMessageTone.neutral:
        return colorScheme.onSurfaceVariant;
      case DsMessageTone.info:
        return DsSemanticColors.info(context);
      case DsMessageTone.success:
        return DsSemanticColors.success(context);
      case DsMessageTone.warning:
        return DsSemanticColors.warning(context);
      case DsMessageTone.error:
        return DsSemanticColors.error(context);
    }
  }

  IconData _defaultIcon(DsMessageTone tone) {
    switch (tone) {
      case DsMessageTone.neutral:
        return Icons.info_outline;
      case DsMessageTone.info:
        return Icons.info_outline;
      case DsMessageTone.success:
        return Icons.check_circle_outline;
      case DsMessageTone.warning:
        return Icons.warning_amber_rounded;
      case DsMessageTone.error:
        return Icons.error_outline;
    }
  }
}

class InlineMessage extends StatelessWidget {
  const InlineMessage({
    required this.message,
    this.tone = DsMessageTone.info,
    this.icon,
    super.key,
  });

  final String message;
  final DsMessageTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InfoBanner(message: message, tone: tone, icon: icon, compact: true);
  }
}
