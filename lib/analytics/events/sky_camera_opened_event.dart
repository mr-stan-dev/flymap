import 'package:flymap/analytics/events/analytics_event.dart';

class SkyCameraOpenedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SkyCameraOpenedEvent({
    required this.hasActiveFlightContext,
    required this.hasLiveLocation,
  });

  final bool hasActiveFlightContext;
  final bool hasLiveLocation;

  @override
  String get firebaseEventName => 'sky_camera_opened';

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};

  @override
  Map<String, Object> get postHogParameters => <String, Object>{
    'has_active_flight_context': hasActiveFlightContext,
    'has_live_location': hasLiveLocation,
    'overlay_mode': 'placeholder_v1',
  };
}
