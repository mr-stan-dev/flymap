import 'package:flymap/analytics/events/analytics_event.dart';

/// Fired when a flight-video preview has successfully generated (tiles loaded,
/// preview visible). The top of the video funnel: preview_ready -> exported
/// -> shared.
class FlightVideoPreviewReadyEvent extends FirebaseAnalyticsEvent {
  const FlightVideoPreviewReadyEvent({
    this.videoSeconds = 0,
    this.tileCount = 0,
  });

  final int videoSeconds;
  final int tileCount;

  @override
  String get firebaseEventName => 'flight_video_preview_ready';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'video_seconds': videoSeconds,
    'tile_count': tileCount,
  };
}
