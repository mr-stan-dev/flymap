import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late OnboardingRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = OnboardingRepository(prefsStorage: UserFlightPrefsStorage());
  });

  test('returns empty profile by default', () async {
    final profile = await repository.getProfile();

    expect(profile, const UserProfile.empty());
  });

  test('persists profile fields', () async {
    const profile = UserProfile(
      displayName: 'Alex',
      flyingFrequency: FlyingFrequency.monthly,
      homeAirportCode: 'egll',
      interests: [UsersInterests.cities, UsersInterests.engineering],
    );

    await repository.saveProfile(profile);

    final stored = await repository.getProfile();
    expect(stored.displayName, 'Alex');
    expect(stored.flyingFrequency, FlyingFrequency.monthly);
    expect(stored.homeAirportCode, 'EGLL');
    expect(stored.interests, const [
      UsersInterests.cities,
      UsersInterests.engineering,
    ]);
    expect(await repository.hasSeenOnboarding(), isNot(true));
  });

  test('reads legacy onboarding seen flag', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'onboarding.seen': true,
    });
    repository = OnboardingRepository(prefsStorage: UserFlightPrefsStorage());

    expect(await repository.hasSeenOnboarding(), isTrue);
  });

  test(
    'markSeen updates only completion flag and keeps prefs intact',
    () async {
      await repository.saveProfile(
        const UserProfile(
          displayName: 'Nina',
          flyingFrequency: FlyingFrequency.fewPerYear,
          homeAirportCode: 'lhr',
          interests: [UsersInterests.cities],
        ),
      );

      await repository.markSeen();
      final profile = await repository.getProfile();

      expect(await repository.hasSeenOnboarding(), isTrue);
      expect(profile.displayName, 'Nina');
      expect(profile.flyingFrequency, FlyingFrequency.fewPerYear);
      expect(profile.homeAirportCode, 'LHR');
      expect(profile.interests, const [UsersInterests.cities]);
    },
  );
}
