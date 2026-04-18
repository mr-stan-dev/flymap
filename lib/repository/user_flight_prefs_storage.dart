import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/entity/user_flight_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserFlightPrefsStorage {
  static const _kFlyingFrequency = 'onboarding.profile.flying_frequency';
  static const _kHomeAirportCode = 'onboarding.profile.home_airport_code';
  static const _kInterests = 'onboarding.profile.interests';

  Future<UserFlightPrefs> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final flyingFrequencyName = prefs.getString(_kFlyingFrequency);
    final storedInterests = prefs.getStringList(_kInterests) ?? const [];

    return UserFlightPrefs(
      flyingFrequency: _parseFlyingFrequency(flyingFrequencyName),
      homeAirportCode: _normalizedCode(prefs.getString(_kHomeAirportCode)),
      interests: storedInterests
          .map(_parseInterest)
          .whereType<UsersInterests>()
          .toList(),
    );
  }

  Future<void> savePrefs(UserFlightPrefs prefsData) async {
    final prefs = await SharedPreferences.getInstance();

    final frequency = prefsData.flyingFrequency;
    if (frequency == null) {
      await prefs.remove(_kFlyingFrequency);
    } else {
      await prefs.setString(_kFlyingFrequency, frequency.name);
    }

    final homeAirportCode = _normalizedCode(prefsData.homeAirportCode);
    if (homeAirportCode == null) {
      await prefs.remove(_kHomeAirportCode);
    } else {
      await prefs.setString(_kHomeAirportCode, homeAirportCode);
    }

    final interests = prefsData.interests
        .map((interest) => interest.name)
        .toList();
    await prefs.setStringList(_kInterests, interests);
  }

  FlyingFrequency? _parseFlyingFrequency(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final frequency in FlyingFrequency.values) {
      if (frequency.name == value) return frequency;
    }
    return null;
  }

  UsersInterests? _parseInterest(String value) {
    for (final interest in UsersInterests.values) {
      if (interest.name == value) return interest;
    }
    return null;
  }

  String? _normalizedCode(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toUpperCase();
    return normalized.isEmpty ? null : normalized;
  }
}
