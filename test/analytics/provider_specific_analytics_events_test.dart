import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/learn_access.dart';

void main() {
  test('Geo Quiz events expose minimal Firebase parameters', () {
    const listOpened = GeoQuizListOpenedEvent(quizCount: 7, isProUser: false);
    const started = GeoQuizStartedEvent(
      quizId: 'countries_europe',
      access: LearnAccess.free,
      isProUser: false,
      solvedCount: 3,
      totalCount: 45,
      isResume: true,
    );
    const completed = GeoQuizCompletedEvent(
      quizId: 'countries_europe',
      totalCount: 45,
      durationSeconds: 120,
      isProUser: false,
    );

    expect(listOpened.firebaseParameters, isEmpty);
    expect(started.firebaseParameters, <String, Object>{
      'quiz_id': 'countries_europe',
    });
    expect(completed.firebaseParameters, <String, Object>{
      'quiz_id': 'countries_europe',
    });
  });

  test('Geo Quiz events expose rich PostHog parameters', () {
    const event = GeoQuizStartedEvent(
      quizId: 'countries_oceania',
      access: LearnAccess.free,
      isProUser: true,
      solvedCount: 4,
      totalCount: 14,
      isResume: true,
    );

    expect(event.postHogParameters, <String, Object>{
      'quiz_id': 'countries_oceania',
      'access': 'free',
      'is_pro_user': true,
      'solved_count': 4,
      'total_count': 14,
      'is_resume': true,
    });
  });

  test('provider membership is encoded by event type', () {
    const event = LearnCategoryOpenedEvent(
      categoryId: 'flight_basics',
      articleCount: 12,
    );

    expect(event, isA<FirebaseAnalyticsEvent>());
    expect(event, isNot(isA<PostHogAnalyticsEvent>()));
    expect(event.firebaseEventName, 'learn_category_opened');
  });

  test('Sky Camera events keep Firebase minimal and PostHog rich', () {
    const opened = SkyCameraOpenedEvent(
      hasActiveFlightContext: false,
      hasLiveLocation: false,
    );
    const captured = SkyCameraPhotoCapturedEvent(
      hasActiveFlightContext: true,
      hasLiveLocation: true,
    );
    const saved = SkyCameraPhotoSavedEvent(
      hasActiveFlightContext: true,
      hasLiveLocation: true,
      saveCleanCopy: true,
      saveOverlayCopy: true,
    );
    const shared = SkyCameraShareTappedEvent(
      hasActiveFlightContext: true,
      hasLiveLocation: false,
    );

    expect(opened.firebaseParameters, isEmpty);
    expect(captured.firebaseParameters, <String, Object>{
      'overlay_mode': 'placeholder_v1',
    });
    expect(saved.postHogParameters, <String, Object>{
      'has_active_flight_context': true,
      'has_live_location': true,
      'overlay_mode': 'placeholder_v1',
      'save_clean_copy': true,
      'save_overlay_copy': true,
    });
    expect(shared.postHogParameters, <String, Object>{
      'has_active_flight_context': true,
      'has_live_location': false,
      'overlay_mode': 'placeholder_v1',
    });
  });
}
