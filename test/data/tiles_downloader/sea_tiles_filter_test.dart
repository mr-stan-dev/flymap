import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/land_mask_provider.dart';
import 'package:flymap/data/tiles_downloader/sea_tiles_filter.dart';
import 'package:flymap/data/tiles_downloader/tile_utils.dart';

void main() {
  group('SeaTilesFilter', () {
    test('does not filter tiles below min zoom', () async {
      final tile = MapTile(7, 10, 10);
      final provider = _FakeLandMaskProvider();
      final filter = SeaTilesFilter(
        landMaskProvider: provider,
        minZoomToFilter: 8,
      );

      final filtered = await filter.filterTiles([tile]);

      expect(filtered, hasLength(1));
      expect(filtered.first.z, 7);
    });

    test('filters sea-only tile at or above min zoom', () async {
      final tile = MapTile(8, 100, 100);
      final provider = _FakeLandMaskProvider();
      final filter = SeaTilesFilter(
        landMaskProvider: provider,
        minZoomToFilter: 8,
      );

      final filtered = await filter.filterTiles([tile]);

      expect(filtered, isEmpty);
    });

    test('keeps sea tile when adjacent tile contains land', () async {
      final tile = MapTile(8, 100, 100);
      final provider = _FakeLandMaskProvider(
        landKeys: {_tileKey(MapTile(8, 101, 100))},
      );
      final filter = SeaTilesFilter(
        landMaskProvider: provider,
        minZoomToFilter: 8,
      );

      final filtered = await filter.filterTiles([tile]);

      expect(filtered, hasLength(1));
      expect(filtered.first.x, 100);
      expect(filtered.first.y, 100);
    });

    test('keeps tile when tile itself contains land', () async {
      final tile = MapTile(8, 100, 100);
      final provider = _FakeLandMaskProvider(landKeys: {_tileKey(tile)});
      final filter = SeaTilesFilter(
        landMaskProvider: provider,
        minZoomToFilter: 8,
      );

      final filtered = await filter.filterTiles([tile]);

      expect(filtered, hasLength(1));
    });
  });
}

class _FakeLandMaskProvider extends LandMaskProvider {
  _FakeLandMaskProvider({Set<String>? landKeys}) : _landKeys = landKeys ?? {};

  final Set<String> _landKeys;

  @override
  Future<void> ensureInitialized() async {}

  @override
  bool tileContainsLand(List<double> bounds) {
    return _landKeys.contains(_boundsKey(bounds));
  }
}

String _tileKey(MapTile tile) => _boundsKey(_boundsForTile(tile));

String _boundsKey(List<double> bounds) {
  return bounds.map((v) => v.toStringAsFixed(6)).join(',');
}

List<double> _boundsForTile(MapTile tile) {
  final n = math.pow(2, tile.z).toDouble();
  final west = tile.x / n * 360.0 - 180.0;
  final east = (tile.x + 1) / n * 360.0 - 180.0;

  double latFromY(int ty) {
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * ty / n)));
    return latRad * 180.0 / math.pi;
  }

  final north = latFromY(tile.y);
  final south = latFromY(tile.y + 1);
  return [south, west, north, east];
}

double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
