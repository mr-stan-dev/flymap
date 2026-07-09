import 'package:flymap/analytics/events/analytics_event.dart';

class ShareWithFriendsEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const ShareWithFriendsEvent({required this.source});

  final String source;

  @override
  String get firebaseEventName => 'share_with_friends';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source,
  };

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
