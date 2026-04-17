import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_window_image.dart';

class OnboardingWelcomeStep extends StatelessWidget {
  const OnboardingWelcomeStep({
    required this.title,
    required this.tagline,
    super.key,
  });

  final String title;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return OnboardingStepScaffold(
      title: title,
      centerHeader: true,
      body: Column(
        children: [
          const OnboardingWindowImage(
            assetPath: 'assets/images/onboarding1.webp',
          ),
          const SizedBox(height: 16),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
