import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/learn_access.dart';

class GeoQuizStartedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const GeoQuizStartedEvent({
    required this.quizId,
    required this.access,
    required this.isProUser,
    required this.solvedCount,
    required this.totalCount,
    required this.isResume,
  });

  final String quizId;
  final LearnAccess access;
  final bool isProUser;
  final int solvedCount;
  final int totalCount;
  final bool isResume;

  @override
  String get firebaseEventName => 'geo_quiz_started';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => <String, Object>{
    'quiz_id': quizId,
    'access': access.name,
    'is_pro_user': isProUser,
    'solved_count': solvedCount,
    'total_count': totalCount,
    'is_resume': isResume,
  };

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'quiz_id': quizId,
  };
}
