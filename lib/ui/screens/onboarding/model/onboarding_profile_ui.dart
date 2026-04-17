import 'package:flutter/material.dart';
import 'package:flymap/entity/onboarding_profile.dart';
import 'package:flymap/i18n/strings.g.dart';

extension FlyingFrequencyUi on FlyingFrequency {
  String title(BuildContext context) {
    return switch (this) {
      FlyingFrequency.firstFlight => context.t.onboarding.frequencyFirstFlight,
      FlyingFrequency.fewPerYear => context.t.onboarding.frequencyFewPerYear,
      FlyingFrequency.monthly => context.t.onboarding.frequencyMonthly,
      FlyingFrequency.frequent => context.t.onboarding.frequencyFrequent,
    };
  }

  IconData get icon {
    return switch (this) {
      FlyingFrequency.firstFlight => Icons.looks_one_rounded,
      FlyingFrequency.fewPerYear => Icons.event_available_rounded,
      FlyingFrequency.monthly => Icons.travel_explore_rounded,
      FlyingFrequency.frequent => Icons.flight_takeoff_rounded,
    };
  }
}

extension OnboardingInterestUi on OnboardingInterest {
  String label(BuildContext context) {
    return switch (this) {
      OnboardingInterest.mountains => context.t.onboarding.interestMountains,
      OnboardingInterest.cities => context.t.onboarding.interestCities,
      OnboardingInterest.coastlines => context.t.onboarding.interestCoastlines,
      OnboardingInterest.landmarks => context.t.onboarding.interestLandmarks,
      OnboardingInterest.aviationHistory =>
        context.t.onboarding.interestAviationHistory,
      OnboardingInterest.engineering =>
        context.t.onboarding.interestEngineering,
    };
  }

  IconData get icon {
    return switch (this) {
      OnboardingInterest.mountains => Icons.terrain_rounded,
      OnboardingInterest.cities => Icons.location_city_rounded,
      OnboardingInterest.coastlines => Icons.waves_rounded,
      OnboardingInterest.landmarks => Icons.account_balance_rounded,
      OnboardingInterest.aviationHistory => Icons.history_edu_rounded,
      OnboardingInterest.engineering => Icons.precision_manufacturing_rounded,
    };
  }
}
