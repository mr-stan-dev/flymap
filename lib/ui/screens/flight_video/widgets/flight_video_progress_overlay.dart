import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

/// Stage label + determinate progress bar for tile prefetch and export.
class FlightVideoProgressOverlay extends StatelessWidget {
  const FlightVideoProgressOverlay({
    required this.label,
    required this.progress,
    super.key,
  });

  final String label;

  /// 0..1
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label $percent%',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
