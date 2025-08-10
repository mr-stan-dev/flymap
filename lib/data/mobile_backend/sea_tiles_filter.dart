import 'dart:math' as math;

import 'package:flymap/data/land_mask_provider.dart';

import 'tile_utils.dart';

/// Filters out sea-only tiles to avoid unnecessary downloads
class SeaTilesFilter {
  final LandMaskProvider landMaskProvider;
  final int minZoomToFilter;

  SeaTilesFilter({LandMaskProvider? landMaskProvider, this.minZoomToFilter = 6})
    : landMaskProvider = landMaskProvider ?? LandMaskProvider();

  /// Returns true if the tile is sea-only (no land present)
  bool isSeaTile(MapTile tile) {
    if (tile.z < minZoomToFilter) return false; // do not filter low zooms

    final bounds = _tileToBounds(tile.x, tile.y, tile.z);
    final hasLand = landMaskProvider.tileContainsLand(bounds);
    return !hasLand;
  }

  /// Filters out sea-only tiles (only for zoom >= minZoomToFilter)
  List<MapTile> filterTiles(Iterable<MapTile> tiles) {
    final result = <MapTile>[];
    for (final tile in tiles) {
      if (tile.z >= minZoomToFilter && isSeaTile(tile)) {
        // skip sea tile
        continue;
      }
      result.add(tile);
    }
    return result;
  }

  /// Compute tile bounds [minLat, minLon, maxLat, maxLon] for WebMercator
  List<double> _tileToBounds(int x, int y, int zoom) {
    final n = math.pow(2, zoom).toDouble();
    final west = x / n * 360.0 - 180.0;
    final east = (x + 1) / n * 360.0 - 180.0;

    double _latFromY(int ty) {
      final latRad = math.atan(_sinh(math.pi * (1 - 2 * ty / n)));
      return latRad * 180.0 / math.pi;
    }

    final north = _latFromY(y);
    final south = _latFromY(y + 1);

    // LandMaskProvider expects [minLat, minLon, maxLat, maxLon]
    return [south, west, north, east];
  }

  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
}
