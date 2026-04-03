import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/onboarding/onboarding_step.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_privacy_visual.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_window_image.dart';

class OnboardingStepContent extends StatelessWidget {
  const OnboardingStepContent({required this.step, super.key});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildVisual(step),
            const SizedBox(height: 24),
            Text(
              step.title(context),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              step.subtitle(context),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisual(OnboardingStep step) {
    final imageAsset = step.imageAsset;
    if (imageAsset != null) {
      return OnboardingWindowImage(assetPath: imageAsset);
    }
    return const OnboardingPrivacyVisual();
  }
}
