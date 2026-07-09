import 'package:flymap/analytics/events/analytics_event.dart';

class SubscriptionStatusChangedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SubscriptionStatusChangedEvent({
    required this.fromStatus,
    required this.toStatus,
    required this.source,
  });

  final String fromStatus;
  final String toStatus;
  final String source;

  @override
  String get firebaseEventName => 'subscription_status_changed';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'from_status': fromStatus,
    'to_status': toStatus,
    'source': source,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
