import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';

class DownloadCompletedEvent extends AnalyticsEvent
    implements FirebaseAnalyticsEvent, PostHogAnalyticsEvent {
  const DownloadCompletedEvent({
    required this.routeLengthKm,
    required this.articlesDownloadedCount,
    required this.mapSizeBytes,
    required this.accessMode,
    required this.routeSource,
  });

  final double routeLengthKm;
  final int articlesDownloadedCount;
  final int mapSizeBytes;
  final String accessMode;
  final FlightRouteSource routeSource;

  @override
  String get firebaseEventName => 'download_completed';

  @override
  Map<String, Object> get firebaseParameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'articles_downloaded_count': articlesDownloadedCount,
    'map_size_mb': double.parse(
      (mapSizeBytes / (1024 * 1024)).toStringAsFixed(1),
    ),
    'access_mode': accessMode,
    'route_source': routeSource.rawValue,
  };

  @override
  String get postHogEventName => firebaseEventName;

  @override
  Map<String, Object> get postHogParameters => firebaseParameters;
}
