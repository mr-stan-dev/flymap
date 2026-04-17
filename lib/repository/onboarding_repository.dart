import 'package:flymap/entity/onboarding_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const _kSeenOnboarding = 'onboarding.seen';
  static const _kDisplayName = 'onboarding.profile.display_name';
  static const _kFlyingFrequency = 'onboarding.profile.flying_frequency';
  static const _kHomeAirportCode = 'onboarding.profile.home_airport_code';
  static const _kInterests = 'onboarding.profile.interests';

  Future<bool> hasSeenOnboarding() async {
    return (await getProfile()).hasCompletedOnboarding;
  }

  Future<void> markSeen() async {
    final profile = await getProfile();
    await saveProfile(profile.copyWith(hasCompletedOnboarding: true));
  }

  Future<OnboardingProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final flyingFrequencyName = prefs.getString(_kFlyingFrequency);
    final storedInterests = prefs.getStringList(_kInterests) ?? const [];

    return OnboardingProfile(
      hasCompletedOnboarding: prefs.getBool(_kSeenOnboarding) ?? false,
      displayName: prefs.getString(_kDisplayName) ?? '',
      flyingFrequency: _parseFlyingFrequency(flyingFrequencyName),
      homeAirportCode: _normalizedCode(prefs.getString(_kHomeAirportCode)),
      interests: storedInterests
          .map(_parseInterest)
          .whereType<OnboardingInterest>()
          .toList(),
    );
  }

  Future<void> saveProfile(OnboardingProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeenOnboarding, profile.hasCompletedOnboarding);
    await prefs.setString(_kDisplayName, profile.displayName.trim());

    final frequency = profile.flyingFrequency;
    if (frequency == null) {
      await prefs.remove(_kFlyingFrequency);
    } else {
      await prefs.setString(_kFlyingFrequency, frequency.name);
    }

    final homeAirportCode = _normalizedCode(profile.homeAirportCode);
    if (homeAirportCode == null) {
      await prefs.remove(_kHomeAirportCode);
    } else {
      await prefs.setString(_kHomeAirportCode, homeAirportCode);
    }

    final interests = profile.interests
        .map((interest) => interest.name)
        .toList();
    await prefs.setStringList(_kInterests, interests);
  }

  Future<OnboardingProfile> updateProfile(
    OnboardingProfile Function(OnboardingProfile current) update,
  ) async {
    final current = await getProfile();
    final updated = update(current);
    await saveProfile(updated);
    return updated;
  }

  FlyingFrequency? _parseFlyingFrequency(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final frequency in FlyingFrequency.values) {
      if (frequency.name == value) return frequency;
    }
    return null;
  }

  OnboardingInterest? _parseInterest(String value) {
    for (final interest in OnboardingInterest.values) {
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
