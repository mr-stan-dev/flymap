import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/map_download_config.dart';

void main() {
  group('MapDownloadConfig.resolveMaxZoom', () {
    test('uses inclusive short-route boundary at 2500km', () {
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 2500.0,
          detailLevel: MapDetailLevel.basic,
        ),
        10,
      );
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 2500.0,
          detailLevel: MapDetailLevel.pro,
        ),
        11,
      );
    });

    test('reduces max zoom for long routes above 2500km', () {
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 2500.1,
          detailLevel: MapDetailLevel.basic,
        ),
        9,
      );
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 2500.1,
          detailLevel: MapDetailLevel.pro,
        ),
        10,
      );
    });
  });

  group('MapDownloadConfig.zoomScaleForEstimate', () {
    test('returns expected scale factors around z10 baseline', () {
      expect(MapDownloadConfig.zoomScaleForEstimate(9), 0.5);
      expect(MapDownloadConfig.zoomScaleForEstimate(10), 1.0);
      expect(MapDownloadConfig.zoomScaleForEstimate(11), 2.0);
    });
  });
}
