import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/tokens/ds_icon_sizes.dart';
import 'package:flymap/ui/design_system/tokens/ds_semantic_colors.dart';
import 'package:flymap/ui/design_system/tokens/ds_spacing.dart';
import 'package:flymap/ui/design_system/widgets/ds_buttons.dart';

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: DsSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: DsSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: DsSpacing.sm),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: DsSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.title,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final errorColor = DsSemanticColors.error(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: 64),
            const SizedBox(height: DsSpacing.md),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: DsSpacing.lg),
              PrimaryButton(
                label: retryLabel,
                onPressed: onRetry,
                leadingIcon: Icons.refresh,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SuccessStateView extends StatelessWidget {
  const SuccessStateView({
    required this.title,
    required this.subtitle,
    this.footer,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final successColor = DsSemanticColors.success(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: successColor, size: 64),
          const SizedBox(height: DsSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: successColor,
            ),
          ),
          const SizedBox(height: DsSpacing.xs),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          const CircularProgressIndicator(),
          if (footer != null) ...[
            const SizedBox(height: DsSpacing.xs),
            Text(
              footer!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProgressStateView extends StatelessWidget {
  const ProgressStateView({
    required this.title,
    required this.progress,
    this.subtitle,
    this.progressText,
    this.secondaryLine,
    this.leadingIcon,
    this.trailingAction,
    super.key,
  });

  final String title;
  final double progress;
  final String? subtitle;
  final String? progressText;
  final String? secondaryLine;
  final IconData? leadingIcon;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).toInt();
    final colorScheme = Theme.of(context).colorScheme;
    final label = progressText ?? '$percent%';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DsSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null)
              Icon(
                leadingIcon,
                size: DsIconSizes.xl,
                color: colorScheme.primary,
              ),
            if (leadingIcon != null) const SizedBox(height: DsSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: DsSpacing.xs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: DsSpacing.md),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: DsSpacing.xs),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            if (secondaryLine != null) ...[
              const SizedBox(height: DsSpacing.xxs),
              Text(
                secondaryLine!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (trailingAction != null) ...[
              const SizedBox(height: DsSpacing.md),
              trailingAction!,
            ],
          ],
        ),
      ),
    );
  }
}
