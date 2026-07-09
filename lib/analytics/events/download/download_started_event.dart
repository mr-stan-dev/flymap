import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/map_detail_level.dart';

class DownloadStartedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const DownloadStartedEvent({
    required this.routeLengthKm,
    required this.mapDetail,
    required this.articlesSelectedCount,
    required this.isProUser,
    required this.accessMode,
    required this.routeSource,
  });

  final double routeLengthKm;
  final MapDetailLevel mapDetail;
  final int articlesSelectedCount;
  final bool isProUser;
  final String accessMode;
  final FlightRouteSource routeSource;

  @override
  String get firebaseEventName => 'download_started';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'map_detail': mapDetail.name,
    'articles_selected_count': articlesSelectedCount,
    'is_pro_user': isProUser ? 1 : 0,
    'access_mode': accessMode,
    'route_source': routeSource.rawValue,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
