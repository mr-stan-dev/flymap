import 'package:equatable/equatable.dart';

enum FlyingFrequency { firstFlight, fewPerYear, monthly, frequent }

enum OnboardingInterest {
  mountains,
  cities,
  coastlines,
  landmarks,
  aviationHistory,
  engineering,
}

class OnboardingProfile extends Equatable {
  const OnboardingProfile({
    required this.hasCompletedOnboarding,
    required this.displayName,
    required this.flyingFrequency,
    required this.homeAirportCode,
    required this.interests,
  });

  const OnboardingProfile.empty()
    : hasCompletedOnboarding = false,
      displayName = '',
      flyingFrequency = null,
      homeAirportCode = null,
      interests = const [];

  final bool hasCompletedOnboarding;
  final String displayName;
  final FlyingFrequency? flyingFrequency;
  final String? homeAirportCode;
  final List<OnboardingInterest> interests;

  bool get hasInterests => interests.isNotEmpty;
  bool get hasProfileDetails =>
      displayName.trim().isNotEmpty ||
      flyingFrequency != null ||
      homeAirportCode != null ||
      interests.isNotEmpty;

  OnboardingProfile copyWith({
    bool? hasCompletedOnboarding,
    String? displayName,
    FlyingFrequency? flyingFrequency,
    bool clearFlyingFrequency = false,
    String? homeAirportCode,
    bool clearHomeAirportCode = false,
    List<OnboardingInterest>? interests,
  }) {
    return OnboardingProfile(
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      displayName: displayName ?? this.displayName,
      flyingFrequency: clearFlyingFrequency
          ? null
          : flyingFrequency ?? this.flyingFrequency,
      homeAirportCode: clearHomeAirportCode
          ? null
          : homeAirportCode ?? this.homeAirportCode,
      interests: interests ?? this.interests,
    );
  }

  @override
  List<Object?> get props => [
    hasCompletedOnboarding,
    displayName,
    flyingFrequency,
    homeAirportCode,
    interests,
  ];
}
