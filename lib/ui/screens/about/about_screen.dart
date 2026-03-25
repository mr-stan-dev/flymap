import 'package:flutter/material.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About Flymap')),
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
                          'Welcome to Flymap',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  Text(
                    'Flymap keeps your route visible in the air. Plan the trip, download your map on the ground, and track your flight offline with confidence.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DsSpacing.sm),
                  const Wrap(
                    spacing: DsSpacing.xs,
                    runSpacing: DsSpacing.xs,
                    children: [
                      StatusChip(
                        label: 'Offline map',
                        tone: StatusChipTone.info,
                        icon: Icons.download_for_offline_rounded,
                      ),
                      StatusChip(
                        label: 'Live dashboard',
                        tone: StatusChipTone.neutral,
                        icon: Icons.speed_rounded,
                      ),
                      StatusChip(
                        label: 'Route sharing',
                        tone: StatusChipTone.success,
                        icon: Icons.ios_share_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            const InfoBanner(
              message:
                  'Before takeoff, download your route map. In flight mode, internet access may be limited or unavailable.',
              tone: DsMessageTone.info,
              icon: Icons.download_for_offline_rounded,
            ),
            const SizedBox(height: DsSpacing.md),
            const SectionCard(
              title: 'What You Can Do',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutFeature(
                    icon: Icons.route_rounded,
                    title: 'Plan your route',
                    text:
                        'Choose departure and arrival airports, then preview the path before downloading.',
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutFeature(
                    icon: Icons.explore_rounded,
                    title: 'Track flight data',
                    text:
                        'Use Dashboard to monitor heading, speed, altitude, and route progress.',
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutFeature(
                    icon: Icons.info_outline_rounded,
                    title: 'Check route details',
                    text:
                        'Open the Info tab for airport details and a clean route overview.',
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutFeature(
                    icon: Icons.ios_share_rounded,
                    title: 'Share your journey',
                    text:
                        'Generate and share a flight map screenshot with route highlights.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            const SectionCard(
              title: 'Quick Start',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutStep(index: 1, text: 'Tap New flight on Home.'),
                  SizedBox(height: DsSpacing.xs),
                  _AboutStep(
                    index: 2,
                    text: 'Choose departure and arrival airports.',
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutStep(
                    index: 3,
                    text:
                        'Open Map preview and download the map before the flight.',
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutStep(
                    index: 4,
                    text:
                        'Open your flight and use Map, Dashboard, and Info in the air.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            const SectionCard(
              title: 'Tips For Better GPS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutTip(
                    text: 'For stronger GPS signal, sit closer to a window.',
                  ),
                  SizedBox(height: DsSpacing.xs),
                  _AboutTip(
                    text:
                        'Signal can drop in the middle of the aircraft. Flymap keeps the last known route view while searching.',
                  ),
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
