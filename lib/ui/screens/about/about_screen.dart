import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      appBar: AppBar(title: Text(t.about.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DsSpacing.md),
          children: [
            const _AboutHero(),
            const SizedBox(height: DsSpacing.md),
            SectionCard(
              title: t.about.missionTitle,
              child: Text(
                t.about.missionText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            SectionCard(
              title: t.about.valuesTitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AboutValue(
                    icon: Icons.travel_explore_rounded,
                    title: t.about.valueCuriosityTitle,
                    text: t.about.valueCuriosityText,
                  ),
                  const SizedBox(height: DsSpacing.md),
                  _AboutValue(
                    icon: Icons.public_rounded,
                    title: t.about.valueGeographyTitle,
                    text: t.about.valueGeographyText,
                  ),
                  const SizedBox(height: DsSpacing.md),
                  _AboutValue(
                    icon: Icons.self_improvement_rounded,
                    title: t.about.valueAwarenessTitle,
                    text: t.about.valueAwarenessText,
                  ),
                  const SizedBox(height: DsSpacing.md),
                  _AboutValue(
                    icon: Icons.offline_bolt_rounded,
                    title: t.about.valueOfflineTitle,
                    text: t.about.valueOfflineText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: DsSpacing.md),
            const _AboutClosing(),
          ],
        ),
      ),
    );
  }
}

/// Bold, mission-first header: a globe, the product name, the one-line promise,
/// and the three values Flymap stands for as chips.
class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DsSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DsRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.75),
              colorScheme.tertiary,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.public_rounded,
              color: colorScheme.onPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          Text(
            t.appName,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            t.about.tagline,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.92),
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: DsSpacing.md),
          Wrap(
            spacing: DsSpacing.xs,
            runSpacing: DsSpacing.xs,
            children: [
              _HeroChip(label: t.about.chipCuriosity),
              _HeroChip(label: t.about.chipGeography),
              _HeroChip(label: t.about.chipAwareness),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpacing.sm,
        vertical: DsSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AboutValue extends StatelessWidget {
  const _AboutValue({
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
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: DsSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: DsSpacing.xxs),
              Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Warm closing note meant to leave users feeling something — and appreciated.
class _AboutClosing extends StatelessWidget {
  const _AboutClosing();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DsSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(DsRadii.lg),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite_rounded,
            color: colorScheme.primary,
            size: 26,
          ),
          const SizedBox(height: DsSpacing.sm),
          Text(
            t.about.closingTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DsSpacing.xxs),
          Text(
            t.about.closingText,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
