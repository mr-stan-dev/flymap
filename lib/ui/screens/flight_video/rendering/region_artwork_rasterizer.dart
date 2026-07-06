import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/logger.dart';
import 'package:jovial_svg/jovial_svg.dart';

/// Rasterizes the same artwork the in-app region chips use into circular
/// [ui.Image]s for the flight-video canvas: country flags from the
/// country_flags package (compiled SVGs) and region-type webp icons.
///
/// Owns every image it produces; dispose with the video session.
class RegionArtworkRasterizer {
  RegionArtworkRasterizer({double size = defaultSize}) : _size = size;

  /// Rendered at 2x the on-screen circle for crispness.
  static const double defaultSize = 96;

  final double _size;
  final Map<String, ui.Image?> _cache = {};
  final Logger _logger = const Logger('RegionArtworkRasterizer');
  bool _disposed = false;

  /// Circular country flag for an ISO alpha-2 code, or null.
  Future<ui.Image?> circularFlag(String? countryCode) async {
    final code = countryCode?.trim().toLowerCase();
    if (code == null || code.length != 2) return null;
    return _cached('flag:$code', () async {
      final scalable = await ScalableImage.fromSIAsset(
        rootBundle,
        'packages/country_flags/res/si/$code.si',
      );
      await scalable.prepareImages();
      final viewport = scalable.viewport;
      if (viewport.width <= 0 || viewport.height <= 0) return null;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, _size, _size),
      );
      canvas.clipPath(
        ui.Path()..addOval(ui.Rect.fromLTWH(0, 0, _size, _size)),
      );
      // Cover-fit the flag into the circle.
      final scale =
          _size / (viewport.width < viewport.height ? viewport.width : viewport.height);
      canvas.translate(_size / 2, _size / 2);
      canvas.scale(scale);
      canvas.translate(
        -viewport.left - viewport.width / 2,
        -viewport.top - viewport.height / 2,
      );
      scalable.paint(canvas);
      scalable.unprepareImages();
      final picture = recorder.endRecording();
      final image = await picture.toImage(_size.round(), _size.round());
      picture.dispose();
      return image;
    });
  }

  /// Circular region-type artwork (same webp the in-app chips use), or null.
  Future<ui.Image?> typeArtwork(RouteRegionType type) async {
    final assetPath = type.assetImagePath;
    if (assetPath == null) return null;
    return _cached('type:${type.apiValue}', () async {
      final data = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: _size.round(),
      );
      final frame = await codec.getNextFrame();
      final source = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(
        recorder,
        ui.Rect.fromLTWH(0, 0, _size, _size),
      );
      canvas.clipPath(
        ui.Path()..addOval(ui.Rect.fromLTWH(0, 0, _size, _size)),
      );
      final sourceSize = source.width < source.height
          ? source.width.toDouble()
          : source.height.toDouble();
      final src = ui.Rect.fromCenter(
        center: ui.Offset(source.width / 2, source.height / 2),
        width: sourceSize,
        height: sourceSize,
      );
      canvas.drawImageRect(
        source,
        src,
        ui.Rect.fromLTWH(0, 0, _size, _size),
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      source.dispose();
      final picture = recorder.endRecording();
      final image = await picture.toImage(_size.round(), _size.round());
      picture.dispose();
      return image;
    });
  }

  Future<ui.Image?> _cached(
    String key,
    Future<ui.Image?> Function() build,
  ) async {
    if (_disposed) return null;
    if (_cache.containsKey(key)) return _cache[key];
    ui.Image? image;
    try {
      image = await build();
    } catch (e) {
      _logger.error('Artwork $key failed: $e');
      image = null;
    }
    if (_disposed) {
      image?.dispose();
      return null;
    }
    _cache[key] = image;
    return image;
  }

  void dispose() {
    _disposed = true;
    for (final image in _cache.values) {
      image?.dispose();
    }
    _cache.clear();
  }
}
