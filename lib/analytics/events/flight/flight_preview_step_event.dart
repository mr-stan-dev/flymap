import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/map_download_config.dart';

enum FlightPreviewAnalyticsStep {
  overview('overview'),
  weather('weather'),
  articles('articles');

  const FlightPreviewAnalyticsStep(this.analyticsValue);

  final String analyticsValue;
}

abstract class FlightPreviewStepEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const FlightPreviewStepEvent({
    required this.step,
    required this.creationAttemptId,
    required this.routeSource,
    required this.routeLength,
    required this.accessMode,
  });

  final FlightPreviewAnalyticsStep step;
  final String creationAttemptId;
  final FlightRouteSource routeSource;
  final RouteLength routeLength;
  final String accessMode;

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'step': step.analyticsValue,
    'creation_attempt_id': creationAttemptId,
    'route_source': routeSource.rawValue,
    'route_length_bucket': _routeBucket(routeLength),
    'access_mode': accessMode,
    'tracking_version': 2,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}

class FlightPreviewStepViewedEvent extends FlightPreviewStepEvent {
  const FlightPreviewStepViewedEvent({
    required super.step,
    required super.creationAttemptId,
    required super.routeSource,
    required super.routeLength,
    required super.accessMode,
  });

  @override
  String get firebaseEventName => 'flight_preview_step_viewed';
}

class FlightPreviewStepCompletedEvent extends FlightPreviewStepEvent {
  const FlightPreviewStepCompletedEvent({
    required super.step,
    required super.creationAttemptId,
    required super.routeSource,
    required super.routeLength,
    required super.accessMode,
  });

  @override
  String get firebaseEventName => 'flight_preview_step_completed';
}

class FlightPreviewStepAbandonedEvent extends FlightPreviewStepEvent {
  const FlightPreviewStepAbandonedEvent({
    required super.step,
    required super.creationAttemptId,
    required super.routeSource,
    required super.routeLength,
    required super.accessMode,
    required this.reason,
  });

  final String reason;

  @override
  String get firebaseEventName => 'flight_preview_step_abandoned';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    ...super.firebaseParameters,
    'reason': reason,
  };
}

String _routeBucket(RouteLength routeLength) {
  return switch (routeLength) {
    RouteLength.short => 'short',
    RouteLength.mid => 'mid',
    RouteLength.long => 'long',
    RouteLength.superLong => 'super_long',
  };
}
