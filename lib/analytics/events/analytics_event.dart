abstract class AnalyticsEvent {
  const AnalyticsEvent();

  String get name;
  Map<String, Object> get parameters;
}
