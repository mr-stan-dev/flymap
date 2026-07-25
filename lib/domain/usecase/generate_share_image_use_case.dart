import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:flymap/ui/screens/share_flight/widgets/card/config/share_image_card_config.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Orchestrates the full flight share-card image generation pipeline:
///
/// 1. Simplify waypoints for the Mapbox URL
/// 2. Fetch satellite map background from Mapbox Static Images API
/// 3. Decode raw bytes to a [ui.Image]
/// 4. Composite flight data overlays on top using [ShareImagePainter]
/// 5. Export the final composited image as PNG to a temp file
class GenerateShareImageUseCase {
  GenerateShareImageUseCase({
    required MapboxStaticImageApi mapboxApi,
    RouteMapImageStore? imageStore,
  }) : _mapboxApi = mapboxApi,
       _imageStore = imageStore;

  final MapboxStaticImageApi _mapboxApi;

  /// Optional disk cache for the base map. Fetch parameters are identical to
  /// the direct API call, so the composited output does not change — the
  /// cache only removes repeat downloads (and enables offline shares).
  final RouteMapImageStore? _imageStore;
  final Logger _logger = const Logger('GenerateShareImageUseCase');

  /// The logical pixel dimensions of the share card.
  /// The actual output is @2x (1080×1600 physical pixels).
  static final int canvasWidth = ShareImageCardConfig.width.toInt();
  static final int canvasHeight = ShareImageCardConfig.height.toInt();
  static const EdgeInsets _overlaySafePadding =
      ShareImageCardConfig.overlaySafePadding;

  /// Generates the share image and returns the file path of the saved PNG.
  ///
  /// Returns `null` if generation fails at any stage.
  Future<String?> call(Flight flight) async {
    try {
      final routePoints = _routePointsForFlight(flight);

      // 1. Calculate the ideal map viewport
      final viewport = StaticRouteMap.buildViewport(
        points: routePoints,
        width: canvasWidth.toDouble(),
        height: canvasHeight.toDouble(),
        padding: _overlaySafePadding,
      );

      // 2. Fetch satellite map background (disk cache first when available;
      // parameters are identical either way, so the output stays the same).
      _logger.log(
        'Fetching static map for ${flight.routeName} (zoom: ${viewport.zoom})',
      );
      final cachedBase = await _imageStore?.getOrFetchShareBase(
        flightId: flight.id,
        viewport: viewport,
        width: canvasWidth,
        height: canvasHeight,
      );
      final mapBytes = cachedBase != null
          ? await cachedBase.readAsBytes()
          : await _mapboxApi.fetchStaticMapImage(
              center: viewport.center,
              zoom: viewport.zoom,
              width: canvasWidth,
              height: canvasHeight,
              retina: true,
            );

      if (mapBytes == null || mapBytes.isEmpty) {
        _logger.error('Failed to fetch static map image');
        return null;
      }

      // 3. Decode to ui.Image
      final mapImage = await _decodeImage(mapBytes);
      if (mapImage == null) {
        _logger.error('Failed to decode static map image');
        return null;
      }

      // 4. Project geographic waypoints to pixel coordinates
      final projectedPoints = StaticRouteMap.projectRoute(
        points: routePoints,
        viewport: viewport,
      ).map((p) => p.toOffset()).toList();

      final planeImage = await _decodeAssetImage(
        ShareImagePainter.planeAssetPath,
      );

      // 5. Composite overlays
      final composited = await _compositeImage(
        flight,
        mapImage,
        projectedPoints,
        planeImage,
      );
      if (composited == null) {
        _logger.error('Failed to composite share image');
        return null;
      }

      // 6. Encode to PNG
      final byteData = await composited.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        _logger.error('Failed to encode composited image to PNG');
        return null;
      }

      // 7. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final routeCode = _safeRouteCode(flight.route.routeCode);
      await _cleanupLegacyRouteFiles(tempDir: tempDir, routeCode: routeCode);
      final filePath = p.join(tempDir.path, 'flymap_share_$routeCode.png');
      final file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      _logger.log('Share image saved: $filePath');
      return filePath;
    } catch (e, stack) {
      _logger.error('GenerateShareImageUseCase failed: $e\n$stack');
      return null;
    }
  }

  String _safeRouteCode(String routeCode) {
    final sanitized = routeCode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return sanitized.isEmpty ? 'route' : sanitized;
  }

  Future<void> _cleanupLegacyRouteFiles({
    required Directory tempDir,
    required String routeCode,
  }) async {
    final legacyPrefix = 'flymap_share_${routeCode}_';
    try {
      await for (final entity in tempDir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.startsWith(legacyPrefix) && name.endsWith('.png')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Best-effort cleanup only; generation should not fail because of this.
    }
  }

  Future<ui.Image?> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image?> _decodeAssetImage(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return _decodeImage(data.buffer.asUint8List());
    } catch (e) {
      _logger.error('Failed to load share image plane asset: $e');
      return null;
    }
  }

  List<LatLng> _routePointsForFlight(Flight flight) {
    final waypoints = flight.waypoints;
    if (waypoints.length >= 2) return waypoints;
    return [flight.departure.latLon, flight.arrival.latLon];
  }

  Future<ui.Image?> _compositeImage(
    Flight flight,
    ui.Image mapBackground,
    List<Offset> projectedPoints,
    ui.Image? planeImage,
  ) async {
    // The output size matches the Mapbox @2x image
    final outputWidth = mapBackground.width;
    final outputHeight = mapBackground.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble()),
    );

    // Draw the satellite map as the background
    canvas.drawImage(mapBackground, Offset.zero, Paint());

    // Scale canvas if map is @2x so painter can use logical pixels
    final isRetina = outputWidth > canvasWidth;
    final scale = isRetina ? 2.0 : 1.0;

    canvas.save();
    canvas.scale(scale, scale);

    // Draw all overlay content
    final painter = ShareImagePainter(
      flight: flight,
      projectedPoints: projectedPoints,
      planeImage: planeImage,
    );
    painter.paint(canvas, Size(outputWidth / scale, outputHeight / scale));

    canvas.restore();

    final picture = recorder.endRecording();
    return picture.toImage(outputWidth, outputHeight);
  }
}
