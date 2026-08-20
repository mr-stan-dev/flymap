import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';

class DownloadFailedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const DownloadFailedEvent({
    required this.stage,
    required this.errorType,
    required this.errorMessage,
    required this.routeLengthKm,
    required this.routeSource,
    this.creationAttemptId,
  });

  final String stage;
  final String errorType;
  final String errorMessage;
  final double routeLengthKm;
  final FlightRouteSource routeSource;
  final String? creationAttemptId;

  @override
  String get firebaseEventName => 'download_failed';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'stage': stage,
    'error_type': errorType,
    'error_message': _normalizeErrorMessage(errorMessage),
    'route_length_km': routeLengthKm.round(),
    'route_source': routeSource.rawValue,
    if (creationAttemptId case final attemptId?)
      'creation_attempt_id': attemptId,
    if (creationAttemptId != null) 'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;

  String _normalizeErrorMessage(String input) {
    final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) return 'unknown';
    const maxLen = 200;
    if (compact.length <= maxLen) return compact;
    return compact.substring(0, maxLen);
  }
}
