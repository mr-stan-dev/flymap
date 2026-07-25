import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/user_profile.dart';
import 'package:flymap/domain/entity/user_flight_prefs.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late UserFlightPrefsStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = UserFlightPrefsStorage();
  });

  test('returns empty prefs by default', () async {
    final prefs = await storage.loadPrefs();

    expect(prefs, const UserFlightPrefs.empty());
  });

  test('persists and normalizes prefs fields', () async {
    const prefs = UserFlightPrefs(
      flyingFrequency: FlyingFrequency.monthly,
      homeAirportCode: ' egll ',
      interests: [UsersInterests.regions, UsersInterests.volcanoes],
    );

    await storage.savePrefs(prefs);
    final loaded = await storage.loadPrefs();

    expect(loaded.flyingFrequency, FlyingFrequency.monthly);
    expect(loaded.homeAirportCode, 'EGLL');
    expect(loaded.interests, const [
      UsersInterests.regions,
      UsersInterests.volcanoes,
    ]);
  });

  test(
    'maps legacy interest names and drops retired topics without a match',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'onboarding.profile.interests': <String>[
          'landmarks',
          'aviationHistory',
          'engineering',
        ],
      });
      storage = UserFlightPrefsStorage();

      final loaded = await storage.loadPrefs();
      // 'aviationHistory' and 'engineering' come from a retired topic set
      // with no meaningful successor; they are dropped instead of being
      // force-mapped to unrelated topics.
      expect(loaded.interests, const [UsersInterests.nationalParks]);
    },
  );
}
