abstract class AnalyticsEvent {
  const AnalyticsEvent();
}

abstract class FirebaseAnalyticsEvent extends AnalyticsEvent {
  const FirebaseAnalyticsEvent();

  String get firebaseEventName;
  Map<String, Object> get firebaseParameters;
}

abstract class PostHogAnalyticsEvent extends AnalyticsEvent {
  const PostHogAnalyticsEvent();

  String get postHogEventName;
  Map<String, Object> get postHogParameters;
}
