import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/map_download_config.dart';

void main() {
  group('MapDownloadConfig.resolveRouteLength', () {
    test(
      'classifies short, mid, long, superLong route buckets by thresholds',
      () {
        expect(MapDownloadConfig.resolveRouteLength(2400.0), RouteLength.short);
        expect(MapDownloadConfig.resolveRouteLength(2500.0), RouteLength.short);
        expect(MapDownloadConfig.resolveRouteLength(2500.1), RouteLength.mid);
        expect(MapDownloadConfig.resolveRouteLength(5000.0), RouteLength.mid);
        expect(MapDownloadConfig.resolveRouteLength(5000.1), RouteLength.long);
        expect(MapDownloadConfig.resolveRouteLength(10000.0), RouteLength.long);
        expect(
          MapDownloadConfig.resolveRouteLength(10000.1),
          RouteLength.superLong,
        );
      },
    );
  });

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

    test('reduces max zoom by one more step for routes above 5000km', () {
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 5000.1,
          detailLevel: MapDetailLevel.basic,
        ),
        8,
      );
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 5000.1,
          detailLevel: MapDetailLevel.pro,
        ),
        9,
      );
    });

    test('reduces max zoom by one more step for routes above 10000km', () {
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 10000.1,
          detailLevel: MapDetailLevel.basic,
        ),
        7,
      );
      expect(
        MapDownloadConfig.resolveMaxZoom(
          distanceKm: 10000.1,
          detailLevel: MapDetailLevel.pro,
        ),
        8,
      );
    });
  });

  group('MapDownloadConfig.resolveCorridorWidthKm', () {
    test('uses strict corridor width thresholds (<2500, <5000, else)', () {
      expect(
        MapDownloadConfig.resolveCorridorWidthKm(2499.9),
        MapDownloadConfig.shortCorridorWidthKm,
      );
      expect(
        MapDownloadConfig.resolveCorridorWidthKm(2500.0),
        MapDownloadConfig.midCorridorWidthKm,
      );
      expect(
        MapDownloadConfig.resolveCorridorWidthKm(4999.9),
        MapDownloadConfig.midCorridorWidthKm,
      );
      expect(
        MapDownloadConfig.resolveCorridorWidthKm(5000.0),
        MapDownloadConfig.longCorridorWidthKm,
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
