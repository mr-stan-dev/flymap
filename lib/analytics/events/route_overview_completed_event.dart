import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';

class RouteOverviewCompletedEvent extends FirebaseAnalyticsEvent {
  const RouteOverviewCompletedEvent({
    required this.isSkipped,
    required this.isProUser,
    required this.routeSource,
  });

  final bool isSkipped;
  final bool isProUser;
  final FlightRouteSource routeSource;

  @override
  String get firebaseEventName => 'route_overview_completed';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'is_skipped': isSkipped,
    'is_pro_user': isProUser,
    'route_source': routeSource.rawValue,
  };
}
