import 'dart:math' as math;

import 'package:flymap/data/land_mask_provider.dart';
import 'package:flymap/map_download_config.dart';

import 'tile_utils.dart';

/// Filters out sea-only tiles to avoid unnecessary downloads
class SeaTilesFilter {
  final LandMaskProvider landMaskProvider;
  final int minZoomToFilter;

  SeaTilesFilter({
    LandMaskProvider? landMaskProvider,
    this.minZoomToFilter = MapDownloadConfig.seaFilterMinZoom,
  }) : landMaskProvider = landMaskProvider ?? LandMaskProvider();

  /// Returns true if the tile is sea-only (no land present)
  bool isSeaTile(MapTile tile) {
    if (tile.z < minZoomToFilter) return false; // do not filter low zooms

    final bounds = _tileToBounds(tile.x, tile.y, tile.z);
    final hasLand = landMaskProvider.tileContainsLand(bounds);
    return !hasLand;
  }

  Future<void> initialize() async {
    await landMaskProvider.ensureInitialized();
  }

  /// Filters out sea-only tiles (only for zoom >= minZoomToFilter)
  Future<List<MapTile>> filterTiles(Iterable<MapTile> tiles) async {
    await initialize();
    final landCache = <String, bool>{};

    bool tileHasLand(MapTile tile) {
      final key = '${tile.z}/${tile.x}/${tile.y}';
      final cached = landCache[key];
      if (cached != null) return cached;
      final bounds = _tileToBounds(tile.x, tile.y, tile.z);
      final hasLand = landMaskProvider.tileContainsLand(bounds);
      landCache[key] = hasLand;
      return hasLand;
    }

    bool hasAdjacentLand(MapTile tile) {
      final maxCoord = (1 << tile.z) - 1;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final neighborY = tile.y + dy;
          if (neighborY < 0 || neighborY > maxCoord) continue;
          var neighborX = tile.x + dx;
          if (neighborX < 0) {
            neighborX += maxCoord + 1;
          } else if (neighborX > maxCoord) {
            neighborX -= maxCoord + 1;
          }
          if (tileHasLand(MapTile(tile.z, neighborX, neighborY))) {
            return true;
          }
        }
      }
      return false;
    }

    final result = <MapTile>[];
    for (final tile in tiles) {
      if (tile.z >= minZoomToFilter &&
          !tileHasLand(tile) &&
          !hasAdjacentLand(tile)) {
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

    double latFromY(int ty) {
      final latRad = math.atan(_sinh(math.pi * (1 - 2 * ty / n)));
      return latRad * 180.0 / math.pi;
    }

    final north = latFromY(y);
    final south = latFromY(y + 1);

    // LandMaskProvider expects [minLat, minLon, maxLat, maxLon]
    return [south, west, north, east];
  }

  double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
}
