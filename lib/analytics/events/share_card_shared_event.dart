import 'package:flymap/analytics/events/analytics_event.dart';

class ShareCardSharedEvent extends FirebaseAnalyticsEvent {
  const ShareCardSharedEvent();

  @override
  String get firebaseEventName => 'share_card_shared';

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};
}
