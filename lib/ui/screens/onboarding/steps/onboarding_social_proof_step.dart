import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';

const _testimonialAvatarColors = <Color>[
  Color(0xFFB54708), // Warm orange
  Color(0xFF027A6A), // Teal
  Color(0xFF6941C6), // Violet
  Color(0xFFC11574), // Magenta
  Color(0xFF175CD3), // Blue
];

/// Social proof shown after the final feature payoff and immediately before
/// onboarding hands off to the subscription flow.
class OnboardingSocialProofStep extends StatelessWidget {
  const OnboardingSocialProofStep({super.key});

  static const int testimonialCardCount = 5;

  @override
  Widget build(BuildContext context) {
    final strings = context.t.onboarding.socialProof;
    final theme = Theme.of(context);
    final testimonials = [
      (
        quote: strings.testimonial1Quote,
        attribution: strings.testimonial1Attribution,
        avatarLetter: 'N',
        rating: 5,
        ratingLabel: strings.ratingLabel(rating: 5),
      ),
      (
        quote: strings.testimonial2Quote,
        attribution: strings.testimonial2Attribution,
        avatarLetter: 'A',
        rating: 5,
        ratingLabel: strings.ratingLabel(rating: 5),
      ),
      (
        quote: strings.testimonial3Quote,
        attribution: strings.testimonial3Attribution,
        avatarLetter: 'A',
        rating: 5,
        ratingLabel: strings.ratingLabel(rating: 5),
      ),
      (
        quote: strings.testimonial4Quote,
        attribution: strings.testimonial4Attribution,
        avatarLetter: 'D',
        rating: 5,
        ratingLabel: strings.ratingLabel(rating: 5),
      ),
      (
        quote: strings.testimonial5Quote,
        attribution: strings.testimonial5Attribution,
        avatarLetter: 'J',
        rating: 5,
        ratingLabel: strings.ratingLabel(rating: 5),
      ),
    ];

    return OnboardingStepScaffold(
      title: strings.title,
      centerHeader: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LaurelFlightCount(
            count: strings.flightCount,
            caption: strings.flightCountCaption,
          ),
          const SizedBox(height: DsSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: DsSpacing.xs),
              Flexible(
                child: Text(
                  strings.testimonialsTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DsSpacing.sm),
          for (var index = 0; index < testimonials.length; index++) ...[
            _TestimonialCard(
              index: index,
              quote: testimonials[index].quote,
              attribution: testimonials[index].attribution,
              avatarLetter: testimonials[index].avatarLetter,
              rating: testimonials[index].rating,
              ratingLabel: testimonials[index].ratingLabel,
            ),
            if (index < testimonials.length - 1)
              const SizedBox(height: DsSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _LaurelFlightCount extends StatelessWidget {
  const _LaurelFlightCount({required this.count, required this.caption});

  final String count;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final semanticsLabel = '$count $caption';

    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 184,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -4,
                top: 0,
                bottom: 0,
                width: 96,
                child: Image.asset(
                  'assets/images/laurel-wreath-laurel_1-left.webp',
                  key: const ValueKey('onboarding-social-proof-laurel-left'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              Positioned(
                right: -4,
                top: 0,
                bottom: 0,
                width: 96,
                child: Image.asset(
                  'assets/images/laurel-wreath-laurel_1-right.webp',
                  key: const ValueKey('onboarding-social-proof-laurel-right'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.58,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      count,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: DsBrandColors.proAmber,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: DsSpacing.xs),
                    Text(
                      caption,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({
    required this.index,
    required this.quote,
    required this.attribution,
    required this.avatarLetter,
    required this.rating,
    required this.ratingLabel,
  });

  final int index;
  final String quote;
  final String attribution;
  final String? avatarLetter;
  final int? rating;
  final String? ratingLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isVerifiedTestimonial = avatarLetter != null && rating != null;

    return Container(
      key: ValueKey('onboarding-testimonial-card-${index + 1}'),
      padding: const EdgeInsets.all(DsSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(DsRadii.lg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isVerifiedTestimonial)
            ExcludeSemantics(
              child: CircleAvatar(
                radius: 20,
                backgroundColor:
                    _testimonialAvatarColors[index %
                        _testimonialAvatarColors.length],
                foregroundColor: Colors.white,
                child: Text(
                  avatarLetter!,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.format_quote_rounded,
                size: 20,
                color: scheme.primary,
              ),
            ),
          const SizedBox(width: DsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rating != null) ...[
                  Semantics(
                    label: ratingLabel,
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var star = 0; star < rating!; star++)
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: DsBrandColors.proAmber,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: DsSpacing.xs),
                ],
                Text(
                  quote,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: DsSpacing.xs),
                Text(
                  attribution,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
