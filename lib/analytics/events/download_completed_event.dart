import 'package:flymap/analytics/events/analytics_event.dart';

class DownloadCompletedEvent extends AnalyticsEvent {
  const DownloadCompletedEvent({
    required this.routeLengthKm,
    required this.articlesDownloadedCount,
    required this.mapSizeBytes,
  });

  final double routeLengthKm;
  final int articlesDownloadedCount;
  final int mapSizeBytes;

  @override
  String get name => 'download_completed';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'articles_downloaded_count': articlesDownloadedCount,
    'map_size_mb': double.parse(
      (mapSizeBytes / (1024 * 1024)).toStringAsFixed(1),
    ),
  };
}
