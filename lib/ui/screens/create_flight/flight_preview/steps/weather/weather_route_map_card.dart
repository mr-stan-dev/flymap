import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/cloud_field_builder.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// The hero of the weather step: the real static map (same Mapbox imagery
/// as the share card, same portrait viewport math), the actual route drawn
/// from its waypoints, and a Windy-style continuous cloud layer rendered
/// from the forecast samples ([CloudFieldBuilder]). Pro sees the clouds and
/// the plane flying the route; free sees the map + route with a lock
/// overlay.
class WeatherRouteMapCard extends StatefulWidget {
  const WeatherRouteMapCard({
    required this.route,
    required this.samples,
    this.areaSamples = const <RouteCloudSample>[],
    required this.isProUser,
    super.key,
  });

  final FlightRoute route;
  final List<RouteCloudSample> samples;

  /// Grid samples covering the rest of the card, so the cloud field spans
  /// the whole picture instead of a corridor-only band.
  final List<RouteCloudSample> areaSamples;
  final bool isProUser;

  @override
  State<WeatherRouteMapCard> createState() => _WeatherRouteMapCardState();
}

class _WeatherRouteMapCardState extends State<WeatherRouteMapCard>
    with SingleTickerProviderStateMixin {
  /// Cloud-field frames spanning the flight; crossfaded by plane progress.
  static const int _cloudFrameCount = 12;

  late final AnimationController _plane = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );

  late final List<LatLng> _routePoints;
  late final StaticMapViewport _viewport;
  late final List<Offset> _projectedRoute;
  late final List<RouteCloudSample> _cloudSamples;
  late final List<Offset> _projectedSamples;
  List<ui.Image> _cloudFrames = const [];
  Uint8List? _mapBytes;

  @override
  void initState() {
    super.initState();
    final waypoints = widget.route.waypointLatLngs;
    _routePoints = waypoints.length >= 2
        ? waypoints
        : [widget.route.departure.latLon, widget.route.arrival.latLon];
    // Square framing: identical for horizontal and vertical routes, and
    // takes less vertical space than the share card's portrait.
    _viewport = StaticRouteMap.buildViewport(
      points: _routePoints,
      width: staticWeatherMapSize,
      height: staticWeatherMapSize,
    );
    _projectedRoute = StaticRouteMap.projectRoute(
      points: _routePoints,
      viewport: _viewport,
    ).map((p) => p.toOffset()).toList(growable: false);
    // Corridor + full-card grid rendered as one field.
    _cloudSamples = [...widget.samples, ...widget.areaSamples];
    _projectedSamples = StaticRouteMap.projectRoute(
      points: _cloudSamples.map((s) => s.latLon).toList(growable: false),
      viewport: _viewport,
    ).map((p) => p.toOffset()).toList(growable: false);

    if (widget.isProUser) {
      _plane.repeat();
      unawaited(_buildCloudField());
    }
    _fetchMapImage();
  }

  /// Rasterizes the samples into continuous cloud frames off the hot path;
  /// the painter draws whatever is ready (nothing until then).
  Future<void> _buildCloudField() async {
    if (_cloudSamples.isEmpty) return;
    final corridor = widget.samples;
    final start =
        (corridor.isNotEmpty ? corridor.first : _cloudSamples.first).timeUtc;
    final end =
        (corridor.isNotEmpty ? corridor.last : _cloudSamples.last).timeUtc;
    final builder = CloudFieldBuilder(
      samples: _cloudSamples,
      positions: _projectedSamples,
      viewportWidth: staticWeatherMapSize,
      viewportHeight: staticWeatherMapSize,
      fieldWidth: 68,
      fieldHeight: 68,
    );
    final buffers = builder.buildFrameBuffers(
      frameCount: end.isAfter(start) ? _cloudFrameCount : 1,
      start: start,
      end: end,
    );
    final images = await Future.wait([
      for (final buffer in buffers)
        _decodeRgba(buffer, builder.fieldWidth, builder.fieldHeight),
    ]);
    if (!mounted) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    setState(() => _cloudFrames = images);
  }

  Future<ui.Image> _decodeRgba(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<void> _fetchMapImage() async {
    // Guarded lookup so widget tests (no DI, no network) fall back to the
    // gradient background instead of crashing.
    if (!GetIt.I.isRegistered<MapboxStaticImageApi>()) return;
    try {
      final bytes = await GetIt.I.get<MapboxStaticImageApi>()
          .fetchStaticMapImage(
            center: _viewport.center,
            zoom: _viewport.zoom,
            width: staticWeatherMapSize.toInt(),
            height: staticWeatherMapSize.toInt(),
          );
      if (!mounted || bytes == null) return;
      setState(() => _mapBytes = bytes);
    } catch (_) {
      // Keep the fallback background — the overlay still communicates.
    }
  }

  @override
  void dispose() {
    _plane.dispose();
    for (final image in _cloudFrames) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t.createFlight.weather;
    final bytes = _mapBytes;

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null)
              Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF16324F), Color(0xFF3E6C99)],
                  ),
                ),
              ),
            // Slight scrim so the white route/clouds read on bright imagery.
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0x1F000000)),
            ),
            AnimatedBuilder(
              animation: _plane,
              builder: (context, _) => CustomPaint(
                painter: _WeatherMapPainter(
                  projectedRoute: _projectedRoute,
                  cloudFrames: _cloudFrames,
                  routeKm: widget.route.displayDistanceKm.toDouble(),
                  departureCode: widget.route.departure.displayCode,
                  arrivalCode: widget.route.arrival.displayCode,
                  showClouds: widget.isProUser,
                  planeProgress: widget.isProUser
                      ? Curves.easeInOutSine.transform(_plane.value)
                      : null,
                ),
              ),
            ),
            if (!widget.isProUser)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xB3000000)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          t.proTeaserTitle,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeatherMapPainter extends CustomPainter {
  _WeatherMapPainter({
    required this.projectedRoute,
    required this.cloudFrames,
    required this.routeKm,
    required this.departureCode,
    required this.arrivalCode,
    required this.showClouds,
    required this.planeProgress,
  });

  /// Offsets in the square viewport space; scaled to canvas size in paint.
  final List<Offset> projectedRoute;

  /// Low-res cloud-field frames spanning the flight, drawn upscaled with
  /// bilinear filtering; empty until built (or for free users).
  final List<ui.Image> cloudFrames;
  final double routeKm;
  final String departureCode;
  final String arrivalCode;
  final bool showClouds;
  final double? planeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    if (projectedRoute.length < 2) return;
    final scale = size.width / staticWeatherMapSize;
    final routePoints = projectedRoute
        .map((p) => p * scale)
        .toList(growable: false);

    if (showClouds) _drawClouds(canvas, size);

    final path = ShareImagePainter.buildRoutePath(
      routePoints,
      routeKm: routeKm,
    );
    // Same teal as the share card route — visible on any satellite imagery.
    canvas.drawPath(
      path,
      Paint()
        ..color = ShareImagePainter.routeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * scale
        ..strokeCap = StrokeCap.round,
    );

    _drawAirport(canvas, routePoints.first, departureCode, scale, size);
    _drawAirport(canvas, routePoints.last, arrivalCode, scale, size);

    final progress = planeProgress;
    if (progress != null) _drawPlane(canvas, path, progress, scale);
  }

  /// The continuous cloud layer: the current flight instant selects two
  /// adjacent field frames, blended exactly (plus-add inside an isolated
  /// layer) so the field morphs smoothly as the plane progresses — clouds
  /// thicken, thin out, and drift instead of stepping.
  void _drawClouds(Canvas canvas, Size size) {
    if (cloudFrames.isEmpty) return;
    final rect = Offset.zero & size;
    final first = cloudFrames.first;
    final src = Rect.fromLTWH(
      0,
      0,
      first.width.toDouble(),
      first.height.toDouble(),
    );
    final progress = planeProgress;
    if (cloudFrames.length == 1 || progress == null) {
      canvas.drawImageRect(
        first,
        src,
        rect,
        Paint()..filterQuality = FilterQuality.low,
      );
      return;
    }

    final framePosition = progress * (cloudFrames.length - 1);
    final index = framePosition.floor().clamp(0, cloudFrames.length - 2);
    final blend = framePosition - index;
    canvas.saveLayer(rect, Paint());
    final paint = Paint()
      ..filterQuality = FilterQuality.low
      ..color = Colors.white.withValues(alpha: 1 - blend);
    canvas.drawImageRect(cloudFrames[index], src, rect, paint);
    paint
      ..color = Colors.white.withValues(alpha: blend)
      ..blendMode = BlendMode.plus;
    canvas.drawImageRect(cloudFrames[index + 1], src, rect, paint);
    canvas.restore();
  }

  void _drawAirport(
    Canvas canvas,
    Offset center,
    String code,
    double scale,
    Size size,
  ) {
    // Share-card endpoint style: white ring with a teal core.
    canvas.drawCircle(center, 7 * scale, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      5.5 * scale,
      Paint()..color = ShareImagePainter.routeColor,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: code,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13 * scale,
          fontWeight: FontWeight.w700,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var labelOrigin = center + Offset(-painter.width / 2, 10 * scale);
    // Keep labels inside the card.
    labelOrigin = Offset(
      labelOrigin.dx.clamp(4, size.width - painter.width - 4),
      labelOrigin.dy.clamp(4, size.height - painter.height - 4),
    );
    painter.paint(canvas, labelOrigin);
  }

  void _drawPlane(Canvas canvas, Path path, double progress, double scale) {
    final metrics = path.computeMetrics().toList(growable: false);
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final tangent = metric.getTangentForOffset(metric.length * progress);
    if (tangent == null) return;

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.flight.codePoint),
        style: TextStyle(
          fontSize: 26 * scale,
          fontFamily: Icons.flight.fontFamily,
          color: ShareImagePainter.routeColor,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(-tangent.angle + math.pi / 2);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WeatherMapPainter oldDelegate) =>
      oldDelegate.planeProgress != planeProgress ||
      oldDelegate.showClouds != showClouds ||
      oldDelegate.cloudFrames != cloudFrames;
}
