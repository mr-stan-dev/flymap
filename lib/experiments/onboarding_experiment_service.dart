import 'package:flutter/foundation.dart';
import 'package:flymap/analytics/posthog_client.dart';

abstract interface class OnboardingExperimentService {
  Future<OnboardingExperimentAssignment> resolve(TargetPlatform platform);
}

enum OnboardingExperimentVariant { control, treatment, notEnrolled }

class OnboardingExperimentAssignment {
  const OnboardingExperimentAssignment({
    required this.experimentKey,
    required this.variant,
    required this.showSocialProof,
    required this.showOnboardingPaywall,
  });

  factory OnboardingExperimentAssignment.currentExperience(
    TargetPlatform platform,
  ) {
    return OnboardingExperimentAssignment(
      experimentKey: switch (platform) {
        TargetPlatform.iOS =>
          PostHogOnboardingExperimentService.socialProofIosFlagKey,
        TargetPlatform.android =>
          PostHogOnboardingExperimentService.onboardingPaywallAndroidFlagKey,
        _ => 'none',
      },
      variant: OnboardingExperimentVariant.notEnrolled,
      showSocialProof: true,
      showOnboardingPaywall: true,
    );
  }

  final String experimentKey;
  final OnboardingExperimentVariant variant;
  final bool showSocialProof;
  final bool showOnboardingPaywall;

  bool get isEnrolled =>
      variant == OnboardingExperimentVariant.control ||
      variant == OnboardingExperimentVariant.treatment;

  String get analyticsVariant => switch (variant) {
    OnboardingExperimentVariant.control => 'control',
    OnboardingExperimentVariant.treatment => 'treatment',
    OnboardingExperimentVariant.notEnrolled => 'not_enrolled',
  };
}

class PostHogOnboardingExperimentService
    implements OnboardingExperimentService {
  PostHogOnboardingExperimentService({
    required PostHogAnalyticsClient postHog,
    this.evaluationTimeout = const Duration(seconds: 3),
  }) : _postHog = postHog;

  static const String socialProofIosFlagKey = 'onboarding-social-proof-ios';
  static const String onboardingPaywallAndroidFlagKey =
      'onboarding-paywall-android';

  final PostHogAnalyticsClient _postHog;
  final Duration evaluationTimeout;

  @override
  Future<OnboardingExperimentAssignment> resolve(
    TargetPlatform platform,
  ) async {
    final flagKey = _flagKeyFor(platform);
    final platformValue = _platformValueFor(platform);
    if (flagKey == null || platformValue == null) {
      return OnboardingExperimentAssignment.currentExperience(platform);
    }

    try {
      await _postHog
          .setPersonPropertiesForFlags(
            properties: <String, Object>{'experiment_platform': platformValue},
          )
          .timeout(evaluationTimeout);
      final rawVariant = await _postHog
          .getFeatureFlag(key: flagKey)
          .timeout(evaluationTimeout);
      final variant = _parseVariant(rawVariant);
      if (variant == null) {
        return OnboardingExperimentAssignment.currentExperience(platform);
      }
      return _assignmentFor(platform, flagKey, variant);
    } catch (_) {
      // A remote experiment must never block onboarding. If PostHog is
      // unavailable, preserve the currently shipped experience.
      return OnboardingExperimentAssignment.currentExperience(platform);
    }
  }

  static String? _flagKeyFor(TargetPlatform platform) => switch (platform) {
    TargetPlatform.iOS => socialProofIosFlagKey,
    TargetPlatform.android => onboardingPaywallAndroidFlagKey,
    _ => null,
  };

  static String? _platformValueFor(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => null,
      };

  static OnboardingExperimentVariant? _parseVariant(Object? rawVariant) {
    return switch (rawVariant) {
      'control' || false => OnboardingExperimentVariant.control,
      'treatment' || true => OnboardingExperimentVariant.treatment,
      _ => null,
    };
  }

  static OnboardingExperimentAssignment _assignmentFor(
    TargetPlatform platform,
    String flagKey,
    OnboardingExperimentVariant variant,
  ) {
    return OnboardingExperimentAssignment(
      experimentKey: flagKey,
      variant: variant,
      showSocialProof:
          platform != TargetPlatform.iOS ||
          variant == OnboardingExperimentVariant.treatment,
      showOnboardingPaywall:
          platform != TargetPlatform.android ||
          variant == OnboardingExperimentVariant.treatment,
    );
  }
}
