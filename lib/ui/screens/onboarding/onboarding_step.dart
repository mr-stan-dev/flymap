import 'package:flutter/widgets.dart';
import 'package:flymap/i18n/strings.g.dart';

/// Ordered onboarding steps shown in the pager.
enum OnboardingStep { explore, story, download, privacy }

extension OnboardingStepUi on OnboardingStep {
  String title(BuildContext context) {
    return switch (this) {
      OnboardingStep.explore => context.t.onboarding.page1Title,
      OnboardingStep.story => context.t.onboarding.page2Title,
      OnboardingStep.download => context.t.onboarding.page3Title,
      OnboardingStep.privacy => context.t.onboarding.page4Title,
    };
  }

  String subtitle(BuildContext context) {
    return switch (this) {
      OnboardingStep.explore => context.t.onboarding.page1Subtitle,
      OnboardingStep.story => context.t.onboarding.page2Subtitle,
      OnboardingStep.download => context.t.onboarding.page3Subtitle,
      OnboardingStep.privacy => context.t.onboarding.page4Subtitle,
    };
  }

  String? get imageAsset {
    return switch (this) {
      OnboardingStep.explore => 'assets/images/onboarding1.webp',
      OnboardingStep.story => 'assets/images/onboarding2.webp',
      OnboardingStep.download => 'assets/images/onboarding3.webp',
      OnboardingStep.privacy => null,
    };
  }

  bool get isPrivacyStep => this == OnboardingStep.privacy;
}
