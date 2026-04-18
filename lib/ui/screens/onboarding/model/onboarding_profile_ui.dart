import 'package:flutter/material.dart';
import 'package:flymap/entity/user_profile.dart';
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

extension UsersInterestsUi on UsersInterests {
  String label(BuildContext context) {
    return switch (this) {
      UsersInterests.mountains => context.t.onboarding.interestMountains,
      UsersInterests.cities => context.t.onboarding.interestCities,
      UsersInterests.coastlines => context.t.onboarding.interestCoastlines,
      UsersInterests.landmarks => context.t.onboarding.interestLandmarks,
      UsersInterests.aviationHistory =>
        context.t.onboarding.interestAviationHistory,
      UsersInterests.engineering =>
        context.t.onboarding.interestEngineering,
    };
  }

  IconData get icon {
    return switch (this) {
      UsersInterests.mountains => Icons.terrain_rounded,
      UsersInterests.cities => Icons.location_city_rounded,
      UsersInterests.coastlines => Icons.waves_rounded,
      UsersInterests.landmarks => Icons.account_balance_rounded,
      UsersInterests.aviationHistory => Icons.history_edu_rounded,
      UsersInterests.engineering => Icons.precision_manufacturing_rounded,
    };
  }
}
