import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';

class FlightSearchDownloadingView extends StatelessWidget {
  const FlightSearchDownloadingView({
    required this.state,
    required this.onCancel,
    super.key,
  });

  final FlightPreviewState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final sections = state.downloadSections;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DsSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DownloadSectionCard(
                  title: context.t.createFlight.downloading.mapSectionTitle,
                  subtitle:
                      sections.map.message ??
                      t.createFlight.downloading.preparingMap,
                  status: sections.map.status,
                  statusLabel: _statusLabel(context, sections.map.status),
                  isCurrentStep:
                      sections.map.status == DownloadSectionStatus.active,
                  trailing: _currentStepBadge(
                    context,
                    isVisible:
                        sections.map.status == DownloadSectionStatus.active,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: DsSpacing.sm),
                    child: LinearProgressIndicator(
                      value: sections.map.progress,
                    ),
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                _DownloadSectionCard(
                  title: context.t.createFlight.downloading.poiSectionTitle,
                  subtitle: _poiSubtitle(context, sections.poi),
                  status: sections.poi.status,
                  statusLabel: _statusLabel(context, sections.poi.status),
                  isCurrentStep:
                      sections.poi.status == DownloadSectionStatus.active,
                  trailing: _currentStepBadge(
                    context,
                    isVisible:
                        sections.poi.status == DownloadSectionStatus.active,
                  ),
                ),
                const SizedBox(height: DsSpacing.sm),
                _DownloadSectionCard(
                  title:
                      context.t.createFlight.downloading.articlesSectionTitle,
                  subtitle: _articlesSubtitle(context, sections.articles),
                  status: sections.articles.status,
                  statusLabel: _statusLabel(context, sections.articles.status),
                  isCurrentStep:
                      sections.articles.status == DownloadSectionStatus.active,
                  trailing: _currentStepBadge(
                    context,
                    isVisible:
                        sections.articles.status ==
                        DownloadSectionStatus.active,
                  ),
                ),
                const SizedBox(height: DsSpacing.md),
                SecondaryButton(
                  onPressed: onCancel,
                  leadingIcon: Icons.close_rounded,
                  label: context.t.createFlight.downloading.cancelDownload,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: InlineMessage(
            message: context.t.createFlight.downloading.doNotClose,
            tone: DsMessageTone.info,
          ),
        ),
      ],
    );
  }

  Widget? _currentStepBadge(BuildContext context, {required bool isVisible}) {
    if (!isVisible) return null;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(DsRadii.pill),
      ),
      child: Text(
        context.t.createFlight.downloading.currentStep,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _statusLabel(BuildContext context, DownloadSectionStatus status) {
    return switch (status) {
      DownloadSectionStatus.pending =>
        context.t.createFlight.downloading.pending,
      DownloadSectionStatus.active =>
        context.t.createFlight.downloading.inProgress,
      DownloadSectionStatus.completed =>
        context.t.createFlight.downloading.completed,
      DownloadSectionStatus.completedWithIssues =>
        context.t.createFlight.downloading.completedWithIssues,
      DownloadSectionStatus.failed => context.t.createFlight.downloading.failed,
      DownloadSectionStatus.skipped =>
        context.t.createFlight.downloading.skipped,
    };
  }

  String _poiSubtitle(BuildContext context, DownloadSectionState section) {
    if (section.total > 0) {
      if (section.failed > 0) {
        return context.t.createFlight.downloading.poiProgressWithFailed(
          completed: section.completed,
          total: section.total,
          failed: section.failed,
        );
      }
      return context.t.createFlight.downloading.poiProgress(
        completed: section.completed,
        total: section.total,
      );
    }
    return section.message ?? t.createFlight.downloading.noPoiSelected;
  }

  String _articlesSubtitle(BuildContext context, DownloadSectionState section) {
    if (section.total > 0) {
      if (section.failed > 0) {
        return context.t.createFlight.downloading.articlesProgressWithFailed(
          completed: section.completed,
          total: section.total,
          failed: section.failed,
        );
      }
      return context.t.createFlight.downloading.articlesProgress(
        completed: section.completed,
        total: section.total,
      );
    }
    return section.message ?? t.createFlight.downloading.noArticlesSelected;
  }
}

class _DownloadSectionCard extends StatelessWidget {
  const _DownloadSectionCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.statusLabel,
    required this.isCurrentStep,
    this.trailing,
    this.child,
  });

  final String title;
  final String subtitle;
  final DownloadSectionStatus status;
  final String statusLabel;
  final bool isCurrentStep;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DsRadii.md),
        border: Border.all(
          color: _showColoredBorder(status)
              ? statusColor
              : Theme.of(context).dividerColor.withValues(alpha: 0.3),
          width: isCurrentStep ? 1.4 : 1,
        ),
      ),
      child: SectionCard(
        title: title,
        trailing: trailing,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), size: 16, color: statusColor),
                const SizedBox(width: DsSpacing.xs),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DsSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }

  bool _showColoredBorder(DownloadSectionStatus status) => switch (status) {
    DownloadSectionStatus.active => true,
    DownloadSectionStatus.completed => true,
    DownloadSectionStatus.completedWithIssues => true,
    DownloadSectionStatus.failed => true,
    DownloadSectionStatus.pending => false,
    DownloadSectionStatus.skipped => false,
  };

  Color _statusColor(BuildContext context, DownloadSectionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      DownloadSectionStatus.pending => colorScheme.onSurfaceVariant,
      DownloadSectionStatus.active => colorScheme.primary,
      DownloadSectionStatus.completed => DsSemanticColors.success(context),
      DownloadSectionStatus.completedWithIssues => DsSemanticColors.warning(
        context,
      ),
      DownloadSectionStatus.failed => DsSemanticColors.error(context),
      DownloadSectionStatus.skipped => colorScheme.onSurfaceVariant,
    };
  }

  IconData _statusIcon(DownloadSectionStatus status) {
    return switch (status) {
      DownloadSectionStatus.pending => Icons.schedule_rounded,
      DownloadSectionStatus.active => Icons.downloading_rounded,
      DownloadSectionStatus.completed => Icons.check_circle_rounded,
      DownloadSectionStatus.completedWithIssues => Icons.warning_amber_rounded,
      DownloadSectionStatus.failed => Icons.error_rounded,
      DownloadSectionStatus.skipped => Icons.remove_circle_outline_rounded,
    };
  }
}
