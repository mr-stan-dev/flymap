import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_palette.dart';

/// Wraps a dashboard section and floats an info button in its top-right corner
/// that opens a bottom sheet explaining the metric.
class MetricInfoSection extends StatelessWidget {
  const MetricInfoSection({
    required this.title,
    required this.body,
    required this.child,
    super.key,
  });

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 6,
          right: 6,
          child: MetricInfoButton(title: title, body: body),
        ),
      ],
    );
  }
}

class MetricInfoButton extends StatelessWidget {
  const MetricInfoButton({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final palette = InstrumentPalette.of(context);
    return IconButton(
      icon: const Icon(Icons.info_outline_rounded, size: 20),
      color: palette.secondaryText,
      tooltip: title,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: () => showMetricInfoSheet(context, title: title, body: body),
    );
  }
}

Future<void> showMetricInfoSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpacing.lg,
            DsSpacing.xs,
            DsSpacing.lg,
            DsSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: DsSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DsSpacing.sm),
              Text(
                body,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const SizedBox(height: DsSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(sheetContext.t.flight.dashboard.metricInfoGotIt),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
