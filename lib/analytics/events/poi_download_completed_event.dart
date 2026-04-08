import 'package:flymap/analytics/events/analytics_event.dart';

class PoiDownloadCompletedEvent extends AnalyticsEvent {
  const PoiDownloadCompletedEvent({
    required this.routeLengthKm,
    required this.totalCount,
    required this.succeededCount,
    required this.failedCount,
    required this.isProUser,
  });

  final double routeLengthKm;
  final int totalCount;
  final int succeededCount;
  final int failedCount;
  final bool isProUser;

  @override
  String get name => 'poi_download_completed';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'total_count': totalCount,
    'succeeded_count': succeededCount,
    'failed_count': failedCount,
    'is_pro_user': isProUser ? 1 : 0,
  };
}
