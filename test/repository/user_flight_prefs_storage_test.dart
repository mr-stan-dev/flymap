import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/entity/user_flight_prefs.dart';
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
      interests: [UsersInterests.cities, UsersInterests.engineering],
    );

    await storage.savePrefs(prefs);
    final loaded = await storage.loadPrefs();

    expect(loaded.flyingFrequency, FlyingFrequency.monthly);
    expect(loaded.homeAirportCode, 'EGLL');
    expect(loaded.interests, const [
      UsersInterests.cities,
      UsersInterests.engineering,
    ]);
  });
}
