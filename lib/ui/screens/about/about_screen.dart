import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.t.about.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DsSpacing.md),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.public_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: DsSpacing.sm),
                      Expanded(
                        child: Text(
                          context.t.about.welcome,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  Text(
                    context.t.about.intro,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  Wrap(
                    spacing: DsSpacing.xs,
                    runSpacing: DsSpacing.xs,
                    children: [
                      StatusChip(
                        label: context.t.about.chipOffline,
                        tone: StatusChipTone.info,
                        icon: Icons.download_for_offline_rounded,
                      ),
                      StatusChip(
                        label: context.t.about.chipDashboard,
                        tone: StatusChipTone.neutral,
                        icon: Icons.speed_rounded,
                      ),
                      StatusChip(
                        label: context.t.about.chipSharing,
                        tone: StatusChipTone.success,
                        icon: Icons.ios_share_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            InfoBanner(
              message: context.t.about.infoBanner,
              tone: DsMessageTone.info,
              icon: Icons.download_for_offline_rounded,
            ),
            const SizedBox(height: DsSpacing.md),
            SectionCard(
              title: context.t.about.whatYouCanDo,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutFeature(
                    icon: Icons.route_rounded,
                    title: context.t.about.featurePlanTitle,
                    text: context.t.about.featurePlanText,
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutFeature(
                    icon: Icons.explore_rounded,
                    title: context.t.about.featureTrackTitle,
                    text: context.t.about.featureTrackText,
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutFeature(
                    icon: Icons.info_outline_rounded,
                    title: context.t.about.featureDetailsTitle,
                    text: context.t.about.featureDetailsText,
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutFeature(
                    icon: Icons.ios_share_rounded,
                    title: context.t.about.featureShareTitle,
                    text: context.t.about.featureShareText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            SectionCard(
              title: context.t.about.quickStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutStep(index: 1, text: context.t.about.step1),
                  SizedBox(height: DsSpacing.xs),
                  _AboutStep(index: 2, text: context.t.about.step2),
                  SizedBox(height: DsSpacing.xs),
                  _AboutStep(index: 3, text: context.t.about.step3),
                  SizedBox(height: DsSpacing.xs),
                  _AboutStep(index: 4, text: context.t.about.step4),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            SectionCard(
              title: context.t.about.tips,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutTip(text: context.t.about.tip1),
                  SizedBox(height: DsSpacing.xs),
                  _AboutTip(text: context.t.about.tip2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutFeature extends StatelessWidget {
  const _AboutFeature({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 16, color: colorScheme.primary),
        ),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: DsSpacing.xxs),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutStep extends StatelessWidget {
  const _AboutStep({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _AboutTip extends StatelessWidget {
  const _AboutTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.check_circle_outline_rounded, size: 14),
        ),
        const SizedBox(width: DsSpacing.xs),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
