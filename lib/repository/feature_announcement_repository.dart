import 'package:flymap/repository/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FeatureAnnouncement {
  geoQuizLearn('geo_quiz_learn');

  const FeatureAnnouncement(this.storageId);

  final String storageId;
}

class FeatureAnnouncementRepository {
  FeatureAnnouncementRepository({required OnboardingRepository onboarding})
    : _onboarding = onboarding;

  static const currentOnboardingFeatureAnnouncements = <FeatureAnnouncement>{
    FeatureAnnouncement.geoQuizLearn,
  };

  static String seenKey(FeatureAnnouncement feature) =>
      'feature_announcement.${feature.storageId}.seen';

  final OnboardingRepository _onboarding;

  Future<bool> shouldShowForExistingUser(FeatureAnnouncement feature) async {
    final hasSeenOnboarding = await _onboarding.hasSeenOnboarding();
    if (!hasSeenOnboarding) return false;

    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(seenKey(feature)) ?? false);
  }

  Future<void> markSeen(FeatureAnnouncement feature) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKey(feature), true);
  }

  Future<void> markCurrentOnboardingFeaturesSeen() async {
    final prefs = await SharedPreferences.getInstance();
    for (final feature in currentOnboardingFeatureAnnouncements) {
      await prefs.setBool(seenKey(feature), true);
    }
  }
}
