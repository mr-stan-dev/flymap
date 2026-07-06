import 'package:flymap/analytics/events/analytics_event.dart';

class FlightVideoGeneratedEvent extends FirebaseAnalyticsEvent {
  const FlightVideoGeneratedEvent({
    required this.success,
    required this.error,
    this.videoSeconds = 0,
    this.tileCount = 0,
    this.exportMs = 0,
  });

  final bool success;
  final String error;
  final int videoSeconds;
  final int tileCount;
  final int exportMs;

  @override
  String get firebaseEventName => 'flight_video_generated';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'success': success ? 1 : 0,
    'error': error,
    'video_seconds': videoSeconds,
    'tile_count': tileCount,
    'export_ms': exportMs,
  };
}
