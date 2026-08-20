import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';

class DownloadCancelledEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const DownloadCancelledEvent({
    required this.routeLengthKm,
    required this.routeSource,
    required this.accessMode,
    required this.creationAttemptId,
  });

  final double routeLengthKm;
  final FlightRouteSource routeSource;
  final String accessMode;
  final String creationAttemptId;

  @override
  String get firebaseEventName => 'download_cancelled';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'route_source': routeSource.rawValue,
    'access_mode': accessMode,
    'creation_attempt_id': creationAttemptId,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
