import 'package:flymap/analytics/events/analytics_event.dart';

class FlightVideoSharedEvent extends FirebaseAnalyticsEvent {
  const FlightVideoSharedEvent();

  @override
  String get firebaseEventName => 'flight_video_shared';

  @override
  Map<String, Object> get firebaseParameters => const <String, Object>{};
}
