import 'package:flymap/analytics/events/analytics_event.dart';

enum PoiMarkerTapSource { mapPreview, flightMap }

extension PoiMarkerTapSourceAnalyticsValue on PoiMarkerTapSource {
  String get analyticsValue {
    return switch (this) {
      PoiMarkerTapSource.mapPreview => 'map_preview',
      PoiMarkerTapSource.flightMap => 'flight_map',
    };
  }
}

class PoiMarkerTappedEvent extends AnalyticsEvent {
  const PoiMarkerTappedEvent({required this.source, required this.poiType});

  final PoiMarkerTapSource source;
  final String poiType;

  @override
  String get name => 'poi_marker_tapped';

  @override
  Map<String, Object> get parameters => <String, Object>{
    'source': source.analyticsValue,
    'poi_type': poiType.isEmpty ? 'unknown' : poiType,
  };
}
