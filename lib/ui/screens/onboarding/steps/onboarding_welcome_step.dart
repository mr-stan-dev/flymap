import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_welcome_video.dart';

/// Welcome step: full-bleed demo-flight video filling the step area, with
/// the title and subtitle overlaid on gradient fades that blend the video
/// edges into the scaffold background (the header row above and the CTA
/// below stay outside the video).
class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        const OnboardingWelcomeVideo(
          videoAssetPath: 'assets/videos/welcome_video_final.mp4',
          posterAssetPath: 'assets/images/onboarding2.webp',
        ),
        // Smooth the video edges into the background above and below.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 160,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    background,
                    background.withValues(alpha: 0),
                  ],
                  stops: const [0.35, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 170,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    background,
                    background.withValues(alpha: 0),
                  ],
                  stops: const [0.4, 1],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 20,
          right: 20,
          child: Text(
            context.t.onboarding.welcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 20,
          right: 20,
          child: Text.rich(
            TextSpan(
              text: '${context.t.appName} ',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(
                  text: context.t.onboarding.welcomeSubtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
