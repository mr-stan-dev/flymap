import 'package:flymap/analytics/events/analytics_event.dart';

class GeoQuizListOpenedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const GeoQuizListOpenedEvent({
    required this.quizCount,
    required this.isProUser,
  });

  final int quizCount;
  final bool isProUser;

  @override
  String get firebaseEventName => 'geo_quiz_list_opened';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => <String, Object>{
    'quiz_count': quizCount,
    'is_pro_user': isProUser,
  };

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};
}
