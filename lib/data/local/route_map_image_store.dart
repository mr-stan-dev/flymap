import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Disk cache of per-flight static route-map images. The images are CLEAN
/// satellite bases (no route drawn) — consumers draw the route themselves at
/// render time via [StaticRouteMap.projectRoute].
///
/// Two variants per flight:
///  - `card`: 4:3 image sized for the home flight-card header, viewport
///    fitted so the whole route is always inside the visible area.
///  - `share`: the share pipeline's base image, fetched with the share
///    flow's own viewport/canvas parameters so the share output is
///    byte-identical to a direct fetch — and sharing works offline once
///    the base is cached.
class RouteMapImageStore {
  RouteMapImageStore({required MapboxStaticImageApi api}) : _api = api;

  static const double cardWidth = 640;
  static const double cardHeight = 480;

  /// Extra bottom padding keeps the route clear of the card's title scrim.
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(44, 44, 44, 100);

  static const String _dirName = 'route_maps';

  final MapboxStaticImageApi _api;
  final Logger _logger = const Logger('RouteMapImageStore');
  final Map<String, Future<File?>> _inFlight = {};

  /// Deterministic card viewport — the card's route painter recomputes this
  /// to project the route over the cached image.
  static StaticMapViewport cardViewport(List<LatLng> points) {
    return StaticRouteMap.buildViewport(
      points: points,
      width: cardWidth,
      height: cardHeight,
      padding: cardPadding,
    );
  }

  Future<File?> getOrFetchCardImage({
    required String flightId,
    required List<LatLng> routePoints,
  }) {
    if (routePoints.length < 2) return Future.value(null);
    return _getOrFetch(
      flightId: flightId,
      suffix: 'card',
      viewport: cardViewport(routePoints),
      width: cardWidth.toInt(),
      height: cardHeight.toInt(),
    );
  }

  /// The share flow passes its own viewport and canvas size so the fetched
  /// bytes are exactly what a direct API call would have returned.
  Future<File?> getOrFetchShareBase({
    required String flightId,
    required StaticMapViewport viewport,
    required int width,
    required int height,
  }) {
    return _getOrFetch(
      flightId: flightId,
      suffix: 'share',
      viewport: viewport,
      width: width,
      height: height,
    );
  }

  Future<File?> _getOrFetch({
    required String flightId,
    required String suffix,
    required StaticMapViewport viewport,
    required int width,
    required int height,
  }) {
    final key = _fileName(flightId, suffix);
    final existing = _inFlight[key];
    if (existing != null) return existing;
    final future = _loadOrFetch(
      key: key,
      viewport: viewport,
      width: width,
      height: height,
    );
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  Future<File?> _loadOrFetch({
    required String key,
    required StaticMapViewport viewport,
    required int width,
    required int height,
  }) async {
    try {
      final dir = await _imagesDir();
      final file = File(p.join(dir.path, key));
      if (await file.exists()) return file;
      final bytes = await _api.fetchStaticMapImage(
        center: viewport.center,
        zoom: viewport.zoom,
        width: width,
        height: height,
        retina: true,
      );
      if (bytes == null || bytes.isEmpty) return null;
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (error) {
      _logger.error('Failed to load route map image "$key": $error');
      return null;
    }
  }

  /// Cache-only lookup for the card image — never fetches. The home card
  /// uses this so thumbnails apply only to flights whose image was fetched
  /// at creation time (no backfill for legacy flights).
  static Future<File?> cachedCardImage(String flightId) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File(
        p.join(docs.path, _dirName, _fileName(flightId, 'card')),
      );
      return await file.exists() ? file : null;
    } catch (_) {
      return null;
    }
  }

  /// Removes the cached images for a deleted flight. Static so the flights
  /// DB service can call it without holding a store instance.
  static Future<void> deleteFilesForFlight(String flightId) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, _dirName));
      if (!await dir.exists()) return;
      for (final suffix in const ['card', 'share']) {
        final file = File(p.join(dir.path, _fileName(flightId, suffix)));
        if (await file.exists()) await file.delete();
      }
    } catch (_) {
      // Cache cleanup is best-effort; orphaned files are harmless.
    }
  }

  static Future<Directory> _imagesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _dirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _fileName(String flightId, String suffix) {
    final safe = flightId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '${safe.isEmpty ? 'flight' : safe}_$suffix.png';
  }
}
