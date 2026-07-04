import 'package:flymap/analytics/events/analytics_event.dart';

class SkyCameraPhotoSavedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SkyCameraPhotoSavedEvent({
    required this.hasActiveFlightContext,
    required this.hasLiveLocation,
    required this.saveCleanCopy,
    required this.saveOverlayCopy,
  });

  final bool hasActiveFlightContext;
  final bool hasLiveLocation;
  final bool saveCleanCopy;
  final bool saveOverlayCopy;

  @override
  String get firebaseEventName => 'sky_camera_photo_saved';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{
    'overlay_mode': 'placeholder_v1',
  };

  @override
  Map<String, Object> get postHogParameters => <String, Object>{
    'has_active_flight_context': hasActiveFlightContext,
    'has_live_location': hasLiveLocation,
    'overlay_mode': 'placeholder_v1',
    'save_clean_copy': saveCleanCopy,
    'save_overlay_copy': saveOverlayCopy,
  };
}
