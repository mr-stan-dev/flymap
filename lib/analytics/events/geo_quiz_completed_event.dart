import 'package:flymap/analytics/events/analytics_event.dart';

class GeoQuizCompletedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const GeoQuizCompletedEvent({
    required this.quizId,
    required this.totalCount,
    required this.durationSeconds,
    required this.isProUser,
  });

  final String quizId;
  final int totalCount;
  final int durationSeconds;
  final bool isProUser;

  @override
  String get firebaseEventName => 'geo_quiz_completed';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => <String, Object>{
    'quiz_id': quizId,
    'total_count': totalCount,
    'duration_seconds': durationSeconds,
    'is_pro_user': isProUser,
  };

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'quiz_id': quizId,
  };
}
