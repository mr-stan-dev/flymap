import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/entity/user_flight_prefs.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const _kSeenOnboarding = 'onboarding.seen';
  static const _kDisplayName = 'onboarding.profile.display_name';

  OnboardingRepository({required UserFlightPrefsStorage prefsStorage})
    : _prefsStorage = prefsStorage;

  final UserFlightPrefsStorage _prefsStorage;

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeenOnboarding) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeenOnboarding, true);
  }

  Future<UserProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsData = await _prefsStorage.loadPrefs();

    return UserProfile(
      displayName: prefs.getString(_kDisplayName) ?? '',
      flyingFrequency: prefsData.flyingFrequency,
      homeAirportCode: prefsData.homeAirportCode,
      interests: prefsData.interests,
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, profile.displayName.trim());

    await _prefsStorage.savePrefs(
      UserFlightPrefs(
        flyingFrequency: profile.flyingFrequency,
        homeAirportCode: profile.homeAirportCode,
        interests: profile.interests,
      ),
    );
  }

  Future<UserProfile> updateProfile(
    UserProfile Function(UserProfile current) update,
  ) async {
    final current = await getProfile();
    final updated = update(current);
    await saveProfile(updated);
    return updated;
  }
}
