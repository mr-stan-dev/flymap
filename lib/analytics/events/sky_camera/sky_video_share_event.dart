import 'package:flymap/analytics/events/analytics_event.dart';

class SkyVideoShareEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SkyVideoShareEvent({
    required this.source,
    required this.result,
    required this.videoCount,
    required this.photoCount,
  });

  final String source;
  final String result;
  final int videoCount;
  final int photoCount;

  @override
  String get firebaseEventName => 'sky_video_share';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'source': source,
    'result': result,
    'video_count': videoCount,
    'photo_count': photoCount,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
