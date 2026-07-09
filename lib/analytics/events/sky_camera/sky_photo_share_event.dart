import 'package:flymap/analytics/events/analytics_event.dart';

class SkyPhotoShareEvent extends FirebaseAnalyticsEvent
    implements PostHogAnalyticsEvent {
  const SkyPhotoShareEvent();

  @override
  String get firebaseEventName => 'sky_photo_share';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};

  @override
  Map<String, Object> get postHogParameters => const <String, Object>{};
}
