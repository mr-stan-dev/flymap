import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/flight_video/video_encoder.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/cloud_field_builder.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_renderer.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:path_provider/path_provider.dart';

/// Builds the weather share renderer (map + cloud frames rebuilt at share
/// time, independent of the on-screen card) and exports it as a PNG story
/// card or a hardware-encoded MP4 of one plane-flight loop.
class WeatherShareService {
  WeatherShareService({
    required MapboxStaticImageApi mapApi,
    required FlightVideoEncoder encoder,
    RouteMapImageStore? imageStore,
  }) : _mapApi = mapApi,
       _encoder = encoder,
       _imageStore = imageStore;

  static const int _cloudFrameCount = 24;
  static const int _cloudFieldResolution = 180;
  static const String _brandLogoAssetPath =
      'assets/images/logo_new_with_text_white.png';
  static const int _videoFps = 24;
  static const double _videoSeconds = 8;
  static const int _videoBitrate = 8 * 1000 * 1000;

  /// Video renders at 720x1280 (2/3 of the card's logical 1080x1920) —
  /// ~2.5x less pixel work per frame, visually indistinguishable after
  /// social-platform recompression. The static image stays full-size.
  static const double _videoPixelRatio = 2 / 3;

  final MapboxStaticImageApi _mapApi;
  final FlightVideoEncoder _encoder;
  final RouteMapImageStore? _imageStore;
  final _logger = const Logger('WeatherShareService');

  /// Prepares all drawable assets. The returned renderer's images belong to
  /// the caller — [disposeRenderer] when done.
  Future<WeatherShareRenderer> buildRenderer({
    required FlightRoute route,
    required FlightWeather weather,
    required WeatherShareData data,
    String? flightId,
  }) async {
    final waypoints = route.waypointLatLngs;
    final routePoints = waypoints.length >= 2
        ? waypoints
        : [route.departure.latLon, route.arrival.latLon];
    final viewport = StaticRouteMap.buildViewport(
      points: routePoints,
      width: staticWeatherMapSize,
      height: staticWeatherMapSize,
    );
    final projectedRoute = StaticRouteMap.projectRoute(
      points: routePoints,
      viewport: viewport,
    ).map((p) => p.toOffset()).toList(growable: false);

    final cloudSamples = [...weather.samples, ...weather.areaSamples];
    final projectedSamples = StaticRouteMap.projectRoute(
      points: cloudSamples.map((s) => s.latLon).toList(growable: false),
      viewport: viewport,
    ).map((p) => p.toOffset()).toList(growable: false);

    final corridor = weather.samples;
    final start = corridor.isNotEmpty
        ? corridor.first.timeUtc
        : weather.departure.timeUtc;
    final end = corridor.isNotEmpty ? corridor.last.timeUtc : start;
    final builder = CloudFieldBuilder(
      samples: cloudSamples,
      positions: projectedSamples,
      viewportWidth: staticWeatherMapSize,
      viewportHeight: staticWeatherMapSize,
      fieldWidth: _cloudFieldResolution,
      fieldHeight: _cloudFieldResolution,
    );
    final cloudFrames = <ui.Image>[];
    for (final buffer in builder.buildFrameBuffers(
      frameCount: cloudSamples.isEmpty || !end.isAfter(start)
          ? 1
          : _cloudFrameCount,
      start: start,
      end: end,
    )) {
      cloudFrames.add(
        await _decodeRgba(buffer, builder.fieldWidth, builder.fieldHeight),
      );
    }

    ui.Image? mapImage;
    try {
      // 540 logical at @2x retina = a sharp ~1080px hero.
      Uint8List? bytes;
      final store = _imageStore;
      if (flightId != null && store != null) {
        // Saved flight: reuse the per-flight cached base the card uses
        // (fetched online at download). A cache hit renders the real map in
        // airplane mode, where a live fetch fails; the viewport matches the
        // card's, so the shared base is identical to what's on screen.
        final file = await store.getOrFetchWeatherImage(
          flightId: flightId,
          routePoints: routePoints,
        );
        if (file != null) bytes = await file.readAsBytes();
      } else {
        // Creation flow (no saved flight yet): fetch the base live.
        bytes = await _mapApi.fetchStaticMapImage(
          center: viewport.center,
          zoom: viewport.zoom,
          width: staticWeatherMapSize.toInt(),
          height: staticWeatherMapSize.toInt(),
        );
      }
      if (bytes != null) {
        mapImage = await decodeImageFromList(bytes);
      }
    } catch (e) {
      // Gradient fallback still communicates.
      _logger.error('share map fetch failed: $e');
    }

    ui.Image? logoImage;
    try {
      final logoData = await rootBundle.load(_brandLogoAssetPath);
      logoImage = await decodeImageFromList(logoData.buffer.asUint8List());
    } catch (e) {
      // Text watermark fallback still brands the card.
      _logger.error('share logo load failed: $e');
    }

    final weatherIcons = <WeatherSymbolKind, ui.Image>{};
    for (final symbol in <WeatherSymbolKind>{
      data.departure.symbol,
      data.arrival.symbol,
    }) {
      try {
        weatherIcons[symbol] = await _loadWeatherIcon(symbol);
      } catch (e) {
        // The renderer retains a native emoji fallback for corrupt or missing
        // assets, so an icon problem must never prevent sharing.
        _logger.error('share weather icon load failed: $e');
      }
    }

    return WeatherShareRenderer(
      data: data,
      projectedRoute: projectedRoute,
      cloudFrames: cloudFrames,
      routeKm: route.displayDistanceKm.toDouble(),
      mapImage: mapImage,
      logoImage: logoImage,
      weatherIcons: weatherIcons,
    );
  }

  void disposeRenderer(WeatherShareRenderer renderer) {
    for (final frame in renderer.cloudFrames) {
      frame.dispose();
    }
    renderer.mapImage?.dispose();
    renderer.logoImage?.dispose();
    for (final image in renderer.weatherIcons.values) {
      image.dispose();
    }
  }

  /// Renders the static story card; returns the PNG file path.
  Future<String> exportImage(WeatherShareRenderer renderer) async {
    // Mid-flight frame: plane and clouds visible.
    final image = await renderer.renderFrame(0.4);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('png encode failed');
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/weather_share_'
          '${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return path;
    } finally {
      image.dispose();
    }
  }

  /// Renders one plane-flight loop as MP4 via the hardware encoder;
  /// returns the file path. [onProgress] gets 0..1. [fps]/[seconds] are
  /// overridable for tests.
  Future<String> exportVideo(
    WeatherShareRenderer renderer, {
    void Function(double progress)? onProgress,
    int fps = _videoFps,
    double seconds = _videoSeconds,
  }) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/weather_share_'
        '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final frameCount = (fps * seconds).round();

    await _encoder.setup(
      width: (WeatherShareRenderer.width * _videoPixelRatio).round(),
      height: (WeatherShareRenderer.height * _videoPixelRatio).round(),
      fps: fps,
      bitrate: _videoBitrate,
      filePath: path,
    );
    try {
      for (var i = 0; i < frameCount; i++) {
        // Same easing as the on-screen card, one full flight per loop.
        final progress = Curves.easeInOutSine.transform(i / (frameCount - 1));
        final image = await renderer.renderFrame(
          progress,
          pixelRatio: _videoPixelRatio,
        );
        try {
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          if (bytes == null) throw StateError('frame readback failed');
          await _encoder.appendFrame(bytes.buffer.asUint8List());
        } finally {
          image.dispose();
        }
        onProgress?.call((i + 1) / frameCount);
      }
      await _encoder.finish();
      return path;
    } catch (e) {
      await _encoder.abort();
      rethrow;
    }
  }

  Future<ui.Image> _decodeRgba(List<int> rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.fromList(rgba),
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<ui.Image> _loadWeatherIcon(WeatherSymbolKind symbol) async {
    final pictureInfo = await vg.loadPicture(
      SvgAssetLoader(symbol.assetPath),
      null,
    );
    try {
      const outputSize = 192;
      final sourceSize = pictureInfo.size;
      final scale = math.min(
        outputSize / sourceSize.width,
        outputSize / sourceSize.height,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.translate(
        (outputSize - sourceSize.width * scale) / 2,
        (outputSize - sourceSize.height * scale) / 2,
      );
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);
      final picture = recorder.endRecording();
      try {
        return await picture.toImage(outputSize, outputSize);
      } finally {
        picture.dispose();
      }
    } finally {
      pictureInfo.picture.dispose();
    }
  }
}
