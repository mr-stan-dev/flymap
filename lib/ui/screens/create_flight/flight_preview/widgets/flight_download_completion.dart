import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class FlightDownloadCompletion extends StatelessWidget {
  const FlightDownloadCompletion({
    required this.onHomePressed,
    this.onSharePressed,
    this.onShareVideoPressed,
    super.key,
  });

  final VoidCallback onHomePressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onShareVideoPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.all(DsSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 72,
            color: DsSemanticColors.success(context),
          ),
          const SizedBox(height: DsSpacing.lg),
          Text(
            t.preview.downloadCongratsTitle,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            t.preview.offlineSavedDetail,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DsSpacing.xxl),
          Text(
            t.preview.shareFlightCard,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DsSpacing.md),
          // New feature, highest priority: share an animated flight video.
          _ShareVideoButton(
            label: t.preview.shareVideo,
            newBadge: t.preview.shareVideoNewBadge,
            onPressed: onShareVideoPressed,
          ),
          const SizedBox(height: DsSpacing.sm),
          SecondaryButton(
            label: t.preview.share,
            onPressed: onSharePressed,
            leadingIcon: Icons.share_rounded,
          ),
          const SizedBox(height: DsSpacing.sm),
          TertiaryButton(
            label: t.preview.home,
            onPressed: onHomePressed,
            leadingIcon: Icons.home_rounded,
          ),
        ],
      ),
    );
  }
}

/// The primary "Share flight video" action with a small NEW badge in the
/// top-right corner so the freshly added feature draws the eye.
class _ShareVideoButton extends StatelessWidget {
  const _ShareVideoButton({
    required this.label,
    required this.newBadge,
    required this.onPressed,
  });

  final String label;
  final String newBadge;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        PrimaryButton(
          label: label,
          onPressed: onPressed,
          leadingIcon: Icons.movie_creation_rounded,
        ),
        Positioned(
          top: -8,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.tertiary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
            child: Text(
              newBadge,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
