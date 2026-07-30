import 'package:flymap/analytics/events/analytics_event.dart';

/// A forecast alert was placed on the system schedule. Deliberate product
/// event (notification funnel) — dual-sink per the PostHog policy.
class ForecastNotificationScheduledEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const ForecastNotificationScheduledEvent({required this.type});

  /// 'forecast_ready' | 'forecast_updated'.
  final String type;

  @override
  String get firebaseEventName => 'forecast_notification_scheduled';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{'type': type};

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}

/// The user opened the app by tapping a forecast alert.
class ForecastNotificationOpenedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const ForecastNotificationOpenedEvent();

  @override
  String get firebaseEventName => 'forecast_notification_opened';

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
