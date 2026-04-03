import 'package:flymap/analytics/events/analytics_event.dart';
import 'package:flymap/entity/map_detail_level.dart';

class DownloadStartedEvent extends AnalyticsEvent {
  const DownloadStartedEvent({
    required this.routeLengthKm,
    required this.mapDetail,
    required this.articlesSelectedCount,
    required this.isProUser,
  });

  final double routeLengthKm;
  final MapDetailLevel mapDetail;
  final int articlesSelectedCount;
  final bool isProUser;

  @override
  String get name => 'download_started';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'route_length_km': routeLengthKm.round(),
    'map_detail': mapDetail.name,
    'articles_selected_count': articlesSelectedCount,
    'is_pro_user': isProUser ? 1 : 0,
  };
}
