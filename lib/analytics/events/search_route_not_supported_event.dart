import 'package:flymap/analytics/events/analytics_event.dart';

class SearchRouteNotSupportedEvent extends AnalyticsEvent {
  const SearchRouteNotSupportedEvent({
    required this.reason,
    required this.routeLengthKm,
  });

  final String reason;
  final double routeLengthKm;

  @override
  String get name => 'search_route_not_supported';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'reason': reason,
    'route_length_km': routeLengthKm.round(),
  };
}
