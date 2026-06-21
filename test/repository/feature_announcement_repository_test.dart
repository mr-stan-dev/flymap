import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FeatureAnnouncementRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = FeatureAnnouncementRepository(
      onboarding: OnboardingRepository(prefsStorage: UserFlightPrefsStorage()),
    );
  });

  test(
    'does not show feature announcement before onboarding is seen',
    () async {
      expect(
        await repository.shouldShowForExistingUser(
          FeatureAnnouncement.geoQuizLearn,
        ),
        isFalse,
      );
    },
  );

  test(
    'shows once for existing onboarded users and persists dismissal',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding.seen', true);

      expect(
        await repository.shouldShowForExistingUser(
          FeatureAnnouncement.geoQuizLearn,
        ),
        isTrue,
      );

      await repository.markSeen(FeatureAnnouncement.geoQuizLearn);

      expect(
        await repository.shouldShowForExistingUser(
          FeatureAnnouncement.geoQuizLearn,
        ),
        isFalse,
      );
      expect(
        prefs.getBool(
          FeatureAnnouncementRepository.seenKey(
            FeatureAnnouncement.geoQuizLearn,
          ),
        ),
        isTrue,
      );
    },
  );

  test('marks current onboarding announcements seen for new users', () async {
    await repository.markCurrentOnboardingFeaturesSeen();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(
        FeatureAnnouncementRepository.seenKey(FeatureAnnouncement.geoQuizLearn),
      ),
      isTrue,
    );
  });
}
