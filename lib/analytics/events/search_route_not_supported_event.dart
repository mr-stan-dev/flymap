import 'package:flymap/analytics/events/analytics_event.dart';

class SearchRouteNotSupportedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const SearchRouteNotSupportedEvent({
    required this.reason,
    required this.routeLengthKm,
  });

  final String reason;
  final double routeLengthKm;

  @override
  String get firebaseEventName => 'search_route_not_supported';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'reason': reason,
    'route_length_km': routeLengthKm.round(),
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
