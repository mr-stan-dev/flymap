import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';

/// XYZ raster tile address. [x] is wrapped into `[0, 2^z)`.
class TileCoord extends Equatable {
  const TileCoord(this.z, this.x, this.y);

  final int z;
  final int x;
  final int y;

  TileCoord? get parent =>
      z <= 0 ? null : TileCoord(z - 1, x >> 1, y >> 1);

  String get cacheKey => '${z}_${x}_$y';

  @override
  List<Object?> get props => [z, x, y];

  @override
  String toString() => 'TileCoord($z/$x/$y)';
}

/// Synchronous tile image lookup used at paint time. Returns null when the
/// tile is not decoded (the renderer then falls back to a parent tile).
abstract class TileResolver {
  ui.Image? imageFor(TileCoord coord);
}
