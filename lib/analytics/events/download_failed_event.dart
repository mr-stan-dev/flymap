import 'package:flymap/analytics/events/analytics_event.dart';

class DownloadFailedEvent extends AnalyticsEvent {
  const DownloadFailedEvent({
    required this.stage,
    required this.errorType,
    required this.routeLengthKm,
  });

  final String stage;
  final String errorType;
  final double routeLengthKm;

  @override
  String get name => 'download_failed';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'stage': stage,
    'error_type': errorType,
    'route_length_km': routeLengthKm.round(),
  };
}
