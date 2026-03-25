import 'package:shared_preferences/shared_preferences.dart';

class OnboardingRepository {
  static const _kSeenOnboarding = 'onboarding.seen';

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSeenOnboarding) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSeenOnboarding, true);
  }
}
