import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/onboarding_profile.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OnboardingRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = OnboardingRepository();
  });

  test('returns empty profile by default', () async {
    final profile = await repository.getProfile();

    expect(profile, const OnboardingProfile.empty());
  });

  test('persists profile fields and completion state', () async {
    const profile = OnboardingProfile(
      hasCompletedOnboarding: true,
      displayName: 'Alex',
      flyingFrequency: FlyingFrequency.monthly,
      homeAirportCode: 'egll',
      interests: [OnboardingInterest.cities, OnboardingInterest.engineering],
    );

    await repository.saveProfile(profile);

    final stored = await repository.getProfile();
    expect(stored.hasCompletedOnboarding, isTrue);
    expect(stored.displayName, 'Alex');
    expect(stored.flyingFrequency, FlyingFrequency.monthly);
    expect(stored.homeAirportCode, 'EGLL');
    expect(stored.interests, const [
      OnboardingInterest.cities,
      OnboardingInterest.engineering,
    ]);
    expect(await repository.hasSeenOnboarding(), isTrue);
  });

  test('reads legacy onboarding seen flag', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding.seen': true,
    });
    repository = OnboardingRepository();

    final profile = await repository.getProfile();

    expect(profile.hasCompletedOnboarding, isTrue);
  });
}
