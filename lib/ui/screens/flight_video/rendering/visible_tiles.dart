import 'dart:math';
import 'dart:ui';

import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/ui/screens/flight_video/rendering/camera_path_planner.dart';
import 'package:flymap/ui/screens/flight_video/rendering/tile_resolver.dart';
import 'package:flymap/ui/screens/flight_video/rendering/world_transform.dart';

/// Highest tile level requested from the raster tile API. Follow zoom is
/// capped well below this; it only guards against bad poses.
const int kMaxTileLevel = 14;

/// Per-frame tile budget. Selection keeps the tiles nearest the camera when
/// the pitched frustum would exceed it (the far edge hides in the haze).
/// MUST stay well below the decoded cache capacity
/// (`VideoTileStore.defaultDecodedCacheCapacity`), otherwise a single frame
/// evicts its own tiles while decoding them.
const int kMaxTilesPerFrame = 80;

/// A tile positioned in camera-centered world pixels for one pose.
///
/// [coord] is the wrapped fetch/cache address; [worldRect] uses unwrapped
/// coordinates so antimeridian crossings render continuously.
class PositionedTile {
  const PositionedTile({required this.coord, required this.worldRect});

  final TileCoord coord;
  final Rect worldRect;
}

/// Tiles visible for [transform]'s pose, positioned for drawing.
///
/// [levelOverride] pins the tile level regardless of the pose zoom — the
/// flight video renders every frame from `CameraPathPlanner.tileLevel` so
/// zoom transitions rescale the same tiles instead of swapping them.
List<PositionedTile> positionedTilesForPose(
  WorldTransform transform, {
  int pad = 1,
  int maxTiles = kMaxTilesPerFrame,
  int? levelOverride,
}) {
  final level = (levelOverride ?? transform.pose.zoom.round()).clamp(
    0,
    kMaxTileLevel,
  );
  final levelTiles = 1 << level;
  // Size of one level-L tile in world px at the pose's fractional zoom.
  final tileWorldSize =
      WorldTransform.tileSizePx * pow(2.0, transform.pose.zoom - level);

  // Visible ground area: the viewport below the horizon clip line,
  // unprojected into world space (a convex quad).
  final size = transform.viewport;
  final top = transform.mapClipTop;
  final corners = <Offset>[
    Offset(0, top),
    Offset(size.width, top),
    Offset(size.width, size.height),
    Offset(0, size.height),
  ];
  final quad = <Offset>[];
  for (final corner in corners) {
    final world = transform.unprojectScreen(corner);
    if (world == null) return const [];
    // To absolute world px, then tile units.
    final absolute = world + transform.cameraWorld;
    quad.add(absolute / tileWorldSize);
  }

  var minTx = double.infinity, maxTx = double.negativeInfinity;
  var minTy = double.infinity, maxTy = double.negativeInfinity;
  for (final p in quad) {
    minTx = min(minTx, p.dx);
    maxTx = max(maxTx, p.dx);
    minTy = min(minTy, p.dy);
    maxTy = max(maxTy, p.dy);
  }

  final x0 = minTx.floor() - pad;
  final x1 = maxTx.floor() + pad;
  final y0 = max(0, minTy.floor() - pad);
  final y1 = min(levelTiles - 1, maxTy.floor() + pad);

  final cameraTile = transform.cameraWorld / tileWorldSize;
  final candidates = <({PositionedTile tile, double distance})>[];
  for (var ty = y0; ty <= y1; ty++) {
    for (var tx = x0; tx <= x1; tx++) {
      final tileRect = Rect.fromLTWH(tx.toDouble(), ty.toDouble(), 1, 1);
      if (!_quadIntersectsRect(quad, tileRect, pad: pad.toDouble())) continue;
      final worldRect = Rect.fromLTWH(
        tx * tileWorldSize - transform.cameraWorld.dx,
        ty * tileWorldSize - transform.cameraWorld.dy,
        tileWorldSize,
        tileWorldSize,
      );
      candidates.add((
        tile: PositionedTile(
          coord: TileCoord(level, tx % levelTiles, ty),
          worldRect: worldRect,
        ),
        distance: (tileRect.center - cameraTile).distanceSquared,
      ));
    }
  }

  if (candidates.length > maxTiles) {
    // Keep the tiles nearest the camera; the far edge sits in the haze band.
    candidates.sort((a, b) => a.distance.compareTo(b.distance));
    candidates.removeRange(maxTiles, candidates.length);
  }
  return [for (final c in candidates) c.tile];
}

/// Wrapped fetch coordinates for [transform]'s pose.
Set<TileCoord> visibleTilesForPose(
  WorldTransform transform, {
  int pad = 1,
  int maxTiles = kMaxTilesPerFrame,
  int? levelOverride,
}) => {
  for (final tile in positionedTilesForPose(
    transform,
    pad: pad,
    maxTiles: maxTiles,
    levelOverride: levelOverride,
  ))
    tile.coord,
};

/// Whole-video tile budget: keeps downloads (and Mapbox API usage) bounded.
const int kMaxManifestTiles = 450;

/// All tiles needed across the whole video at the planner's single tile
/// level, sampled every [frameStride] frames, plus each tile's parent (the
/// draw-time fallback if a download fails — without it a failed tile would
/// stay a hole for the whole video).
Set<TileCoord> buildTileManifest({
  required CameraPathPlanner planner,
  required FlightVideoSpec spec,
  int frameStride = 5,
}) {
  final tiles = <TileCoord>{};
  final lastFrame = spec.frameCount - 1;
  for (var frame = 0; frame <= lastFrame; frame += frameStride) {
    tiles.addAll(
      visibleTilesForPose(
        planner.transformAt(frame / lastFrame),
        levelOverride: planner.tileLevel,
      ),
    );
  }
  tiles.addAll(
    visibleTilesForPose(
      planner.transformAt(1),
      levelOverride: planner.tileLevel,
    ),
  );
  return {
    ...tiles,
    for (final tile in tiles)
      if (tile.parent != null) tile.parent!,
  };
}

/// Builds the video's tile manifest, dropping to a coarser tile level until
/// the whole video fits [maxTiles].
Set<TileCoord> buildBudgetedTileManifest({
  required CameraPathPlanner planner,
  required FlightVideoSpec spec,
  int maxTiles = kMaxManifestTiles,
  int frameStride = 5,
}) {
  var manifest = buildTileManifest(
    planner: planner,
    spec: spec,
    frameStride: frameStride,
  );
  while (manifest.length > maxTiles && planner.lowerTileLevel()) {
    manifest = buildTileManifest(
      planner: planner,
      spec: spec,
      frameStride: frameStride,
    );
  }
  return manifest;
}

/// Convex-quad vs axis-aligned rect intersection (separating axis test).
/// [pad] inflates the quad's projection to keep a safety ring of tiles.
bool _quadIntersectsRect(List<Offset> quad, Rect rect, {double pad = 0}) {
  // Axis-aligned axes: compare bounding intervals directly.
  var minQx = double.infinity, maxQx = double.negativeInfinity;
  var minQy = double.infinity, maxQy = double.negativeInfinity;
  for (final p in quad) {
    minQx = min(minQx, p.dx);
    maxQx = max(maxQx, p.dx);
    minQy = min(minQy, p.dy);
    maxQy = max(maxQy, p.dy);
  }
  if (maxQx + pad < rect.left || minQx - pad > rect.right) return false;
  if (maxQy + pad < rect.top || minQy - pad > rect.bottom) return false;

  // Quad edge normals.
  final rectCorners = <Offset>[
    rect.topLeft,
    rect.topRight,
    rect.bottomRight,
    rect.bottomLeft,
  ];
  for (var i = 0; i < quad.length; i++) {
    final a = quad[i];
    final b = quad[(i + 1) % quad.length];
    final normal = Offset(-(b.dy - a.dy), b.dx - a.dx);
    final length = normal.distance;
    if (length < 1e-12) continue;

    var minQ = double.infinity, maxQ = double.negativeInfinity;
    for (final p in quad) {
      final d = p.dx * normal.dx + p.dy * normal.dy;
      minQ = min(minQ, d);
      maxQ = max(maxQ, d);
    }
    var minR = double.infinity, maxR = double.negativeInfinity;
    for (final p in rectCorners) {
      final d = p.dx * normal.dx + p.dy * normal.dy;
      minR = min(minR, d);
      maxR = max(maxR, d);
    }
    final padProjected = pad * length;
    if (maxQ + padProjected < minR || minQ - padProjected > maxR) return false;
  }
  return true;
}
