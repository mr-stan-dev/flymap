import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/posthog_client.dart';
import 'package:flymap/experiments/onboarding_experiment_service.dart';

void main() {
  test(
    'iOS treatment shows social proof and records platform targeting',
    () async {
      final client = _FakePostHogClient('treatment');
      final service = PostHogOnboardingExperimentService(postHog: client);

      final assignment = await service.resolve(TargetPlatform.iOS);

      expect(assignment.experimentKey, 'onboarding-social-proof-ios');
      expect(assignment.variant, OnboardingExperimentVariant.treatment);
      expect(assignment.showSocialProof, isTrue);
      expect(assignment.showOnboardingPaywall, isTrue);
      expect(client.properties, <String, Object>{'experiment_platform': 'ios'});
      expect(client.requestedFlagKey, 'onboarding-social-proof-ios');
    },
  );

  test('iOS control hides social proof', () async {
    final service = PostHogOnboardingExperimentService(
      postHog: _FakePostHogClient('control'),
    );

    final assignment = await service.resolve(TargetPlatform.iOS);

    expect(assignment.variant, OnboardingExperimentVariant.control);
    expect(assignment.showSocialProof, isFalse);
    expect(assignment.showOnboardingPaywall, isTrue);
  });

  test('Android control skips only the onboarding paywall', () async {
    final client = _FakePostHogClient('control');
    final service = PostHogOnboardingExperimentService(postHog: client);

    final assignment = await service.resolve(TargetPlatform.android);

    expect(assignment.experimentKey, 'onboarding-paywall-android');
    expect(assignment.variant, OnboardingExperimentVariant.control);
    expect(assignment.showSocialProof, isTrue);
    expect(assignment.showOnboardingPaywall, isFalse);
    expect(client.properties, <String, Object>{
      'experiment_platform': 'android',
    });
    expect(client.requestedFlagKey, 'onboarding-paywall-android');
  });

  test('missing flag keeps current experience and is not enrolled', () async {
    final service = PostHogOnboardingExperimentService(
      postHog: _FakePostHogClient(null),
    );

    final assignment = await service.resolve(TargetPlatform.android);

    expect(assignment.variant, OnboardingExperimentVariant.notEnrolled);
    expect(assignment.isEnrolled, isFalse);
    expect(assignment.showSocialProof, isTrue);
    expect(assignment.showOnboardingPaywall, isTrue);
  });

  test(
    'unsupported platforms keep current experience without flag lookup',
    () async {
      final client = _FakePostHogClient('treatment');
      final service = PostHogOnboardingExperimentService(postHog: client);

      final assignment = await service.resolve(TargetPlatform.macOS);

      expect(assignment.experimentKey, 'none');
      expect(assignment.isEnrolled, isFalse);
      expect(client.requestedFlagKey, isNull);
      expect(client.properties, isNull);
    },
  );
}

class _FakePostHogClient implements PostHogAnalyticsClient {
  _FakePostHogClient(this.flagValue);

  final Object? flagValue;
  Map<String, Object>? properties;
  String? requestedFlagKey;

  @override
  Future<Object?> getFeatureFlag({required String key}) async {
    requestedFlagKey = key;
    return flagValue;
  }

  @override
  Future<void> setPersonPropertiesForFlags({
    required Map<String, Object> properties,
    bool reloadFeatureFlags = true,
  }) async {
    this.properties = properties;
  }

  @override
  Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async {}

  @override
  Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
    Map<String, Object>? userPropertiesSetOnce,
  }) async {}

  @override
  Future<void> setPersonProperties({
    Map<String, Object>? userPropertiesToSet,
    Map<String, Object>? userPropertiesToSetOnce,
  }) async {}

  @override
  Future<void> setup({
    required String projectToken,
    required String host,
    required bool debug,
    required bool captureApplicationLifecycleEvents,
  }) async {}
}
