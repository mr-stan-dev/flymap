import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class GeoQuizEntryCard extends StatelessWidget {
  const GeoQuizEntryCard({
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.imageAssetPath,
    required this.imageKey,
    required this.finishedCount,
    required this.inProgressCount,
    required this.totalCount,
    super.key,
    this.showNewBadge = false,
  });

  static const newBadgeKey = Key('learn.geo_quiz.new_badge');
  static const countriesImageKey = Key('learn.geo_quiz.image');
  static const geographyImageKey = Key('learn.geo_quiz.geography_image');
  static const finishedMetricKey = Key('learn.geo_quiz.finished_metric');
  static const inProgressMetricKey = Key('learn.geo_quiz.in_progress_metric');
  static const allCompletedMetricKey = Key(
    'learn.geo_quiz.all_completed_metric',
  );

  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String imageAssetPath;
  final Key imageKey;
  final int finishedCount;
  final int inProgressCount;
  final int totalCount;
  final bool showNewBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(14, 14, showNewBadge ? 62 : 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GeoQuizIllustration(
                    size: 72,
                    assetPath: imageAssetPath,
                    imageKey: imageKey,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 9),
                        _CompactProgress(
                          finishedCount: finishedCount,
                          inProgressCount: inProgressCount,
                          totalCount: totalCount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showNewBadge)
              const Positioned(top: 12, right: 12, child: _NewBadge()),
          ],
        ),
      ),
    );
  }
}

class _CompactProgress extends StatelessWidget {
  const _CompactProgress({
    required this.finishedCount,
    required this.inProgressCount,
    required this.totalCount,
  });

  final int finishedCount;
  final int inProgressCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = DsSemanticColors.success(context);
    final hasProgress = finishedCount > 0 || inProgressCount > 0;
    if (!hasProgress) {
      return Row(
        children: [
          Icon(
            Icons.play_circle_outline_rounded,
            color: theme.colorScheme.primary,
            size: 15,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              context.t.learn.geoQuiz.progressReady,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    if (totalCount > 0 && finishedCount >= totalCount) {
      return _ProgressMetric(
        key: GeoQuizEntryCard.allCompletedMetricKey,
        icon: Icons.check_circle_rounded,
        label: context.t.learn.geoQuiz.progressAllCompleted,
        color: success,
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        if (inProgressCount > 0)
          _ProgressMetric(
            key: GeoQuizEntryCard.inProgressMetricKey,
            icon: Icons.donut_small_rounded,
            label: context.t.learn.geoQuiz.progressInProgress(
              count: inProgressCount,
            ),
            color: theme.colorScheme.primary,
          ),
        if (finishedCount > 0)
          _ProgressMetric(
            key: GeoQuizEntryCard.finishedMetricKey,
            icon: Icons.check_circle_rounded,
            label: context.t.learn.geoQuiz.progressFinished(
              count: finishedCount,
            ),
            color: success,
          ),
      ],
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.label,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeoQuizIllustration extends StatelessWidget {
  const _GeoQuizIllustration({
    required this.size,
    required this.assetPath,
    this.imageKey,
  });

  final double size;
  final String assetPath;
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.9),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            assetPath,
            key: imageKey,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: GeoQuizEntryCard.newBadgeKey,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          context.t.learn.geoQuiz.newBadge,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onError,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
