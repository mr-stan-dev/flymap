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
}
