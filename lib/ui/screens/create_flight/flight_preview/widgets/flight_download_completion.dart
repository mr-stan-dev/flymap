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
          PrimaryButton(
            label: t.preview.shareVideo,
            onPressed: onShareVideoPressed,
            leadingIcon: Icons.movie_creation_rounded,
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
