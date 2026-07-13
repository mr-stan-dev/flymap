import 'package:flymap/analytics/events/analytics_event.dart';

class SkyVideoCaptureEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SkyVideoCaptureEvent({
    required this.hasActiveFlightContext,
    required this.hasLiveLocation,
    required this.durationSeconds,
  });

  final bool hasActiveFlightContext;
  final bool hasLiveLocation;
  final int durationSeconds;

  @override
  String get firebaseEventName => 'sky_video_captured';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'duration_seconds': durationSeconds,
  };

  @override
  Map<String, Object> get postHogParameters => <String, Object>{
    'has_active_flight_context': hasActiveFlightContext,
    'has_live_location': hasLiveLocation,
    'duration_seconds': durationSeconds,
  };
}
