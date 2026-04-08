import 'package:flymap/entity/map_detail_level.dart';

class PoiSelectionConfig {
  PoiSelectionConfig._();

  static const int basicMaxPois = 10;
  static const int proMaxPois = 60;

  static const int basicSegmentCount = 8;
  static const int proSegmentCount = 20;

  static const int basicCityCap = 2;
  static const int proCityCap = 12;

  /// Minimum segment index gap between two selected cities.
  /// Expressed as ~20% of the segment count so the effective spacing stays
  /// proportional regardless of how many segments a mode uses.
  static int minCitySegmentGap(MapDetailLevel mapDetail) =>
      (segmentCount(mapDetail) * 0.20).round().clamp(2, 6);

  /// Soft caps to keep one type from dominating the map.
  static const int basicSoftCapPerType = 4;
  static const int proSoftCapPerType = 40;

  static const int basicPrefetchLimit = 1200;
  static const int proPrefetchLimit = 3000;

  static int maxPois(MapDetailLevel mapDetail) {
    return mapDetail == MapDetailLevel.pro ? proMaxPois : basicMaxPois;
  }

  static int segmentCount(MapDetailLevel mapDetail) {
    return mapDetail == MapDetailLevel.pro
        ? proSegmentCount
        : basicSegmentCount;
  }

  static int cityCap(MapDetailLevel mapDetail) {
    return mapDetail == MapDetailLevel.pro ? proCityCap : basicCityCap;
  }

  static int softCapPerType(MapDetailLevel mapDetail) {
    return mapDetail == MapDetailLevel.pro
        ? proSoftCapPerType
        : basicSoftCapPerType;
  }

  static int prefetchLimit(MapDetailLevel mapDetail) {
    return mapDetail == MapDetailLevel.pro
        ? proPrefetchLimit
        : basicPrefetchLimit;
  }
}
