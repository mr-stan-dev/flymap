import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_video_spec.dart';
import 'package:flymap/ui/screens/flight_video/rendering/camera_path_planner.dart';
import 'package:flymap/ui/screens/flight_video/rendering/plane_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/region_highlight_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/route_path_model.dart';
import 'package:flymap/ui/screens/flight_video/rendering/tile_resolver.dart';
import 'package:flymap/ui/screens/flight_video/rendering/visible_tiles.dart';
import 'package:flymap/ui/screens/flight_video/rendering/world_transform.dart';
import 'package:flymap/utils/route_utils.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Paints one complete flight-video frame for a normalized time `t`.
///
/// Works in the output coordinate space ([FlightVideoSpec.width] x
/// [FlightVideoSpec.height]); the preview widget scales the canvas instead of
/// re-laying-out, so preview and export are pixel-identical.
class MapFrameRenderer {
  MapFrameRenderer({
    required this.tiles,
    required this.route,
    required this.planner,
    required this.flight,
    required this.spec,
    this.planeSprite,
    PlaneModel? planeModel,
    double planeYawOffset = 0,
    this.brandLogo,
    this.regionHighlights,
    this.endCardChips = const [],
    this.routeColor = _routeCyan,
    double tickerTotalKm = 0,
    double tickerUnitFactor = 1,
    String tickerUnitLabel = 'km',
    String attributionText = defaultAttribution,
    String? statsDistanceText,
    String? statsDurationText,
    String brandText = 'Flymap',
    String madeWithText = '',
  }) : _planeModel = planeModel,
       _planeMesh = planeModel == null
           ? null
           : PlaneMeshPainter(planeModel, modelYawOffset: planeYawOffset),
       _tickerTotalKm = tickerTotalKm,
       _tickerUnitFactor = tickerUnitFactor,
       _tickerUnitLabel = tickerUnitLabel,
       _attributionText = attributionText,
       _statsDistanceText = statsDistanceText,
       _statsDurationText = statsDurationText,
       _brandText = brandText,
       _madeWithText = madeWithText;

  /// Mapbox Static Tiles carry no baked attribution, so every exported frame
  /// must render it (satellite imagery adds Maxar).
  static const String defaultAttribution = '© Mapbox © OpenStreetMap © Maxar';

  static const Color _routeCyan = Color(0xFF47EFFF);
  static const Color _pillBackground = Color(0xB2122235);
  static const Color _pillBorder = Color(0x8896AEC8);

  /// Same violet the in-app map uses for the selected region overlay.
  static const Color _skyTop = Color(0xFF3D6CA3);
  static const Color _skyHorizon = Color(0xFFC3D9E8);
  static const double _planeWidth = 116;
  static const double _planeHeight = 156;

  /// The tiles painted each frame. Swappable via [retile] so a map-style
  /// change reuses this renderer (and all its style-independent artefacts)
  /// instead of rebuilding the whole session.
  TileResolver tiles;
  final RoutePathModel route;
  final CameraPathPlanner planner;
  final Flight flight;
  final FlightVideoSpec spec;
  final ui.Image? planeSprite;
  final PlaneModel? _planeModel;
  final PlaneMeshPainter? _planeMesh;
  final ui.Image? brandLogo;
  final RegionHighlightModel? regionHighlights;
  final List<RegionChipData> endCardChips;

  /// Trail/marker/pulse color, chosen per map style for contrast (cyan on
  /// satellite imagery, a vivid red on light terrain styles). Swappable via
  /// [retile].
  Color routeColor;

  /// Pro users can switch the brand watermark off; the map attribution is a
  /// license requirement and is never affected by this flag.
  bool watermarkEnabled = true;

  /// Static text layouts, built once — TextPainter.layout every frame is
  /// wasted CPU in the export loop.
  final Map<RegionHighlight, TextPainter> _pinLabelCache = {};
  /// "Mystery destination" mode: header shows "?" instead of the arrival
  /// airport until the plane lands. Mutable like [watermarkEnabled] so the
  /// settings toggle applies live without rebuilding the session.
  bool mysteryDestination = false;

  /// Country pins on the map. Off by default — a clean route reads better;
  /// users opt in from settings. Mutable so the toggle applies live.
  bool showPins = false;

  /// The outro info card (route, distance/duration, country chips). On by
  /// default; users can hide it for a pure map ending. Mutable.
  bool showEndCard = true;

  // Two header variants, both laid out once: destination hidden behind "?"
  // during the flight (open-ended hook), the real airport revealed the
  // moment the plane lands.
  TextPainter? _headerTitleMystery;
  TextPainter? _headerTitleRevealed;
  TextPainter? _headerSubtitleMystery;
  TextPainter? _headerSubtitleRevealed;
  TextPainter? _attribution;
  final double _tickerTotalKm;
  final double _tickerUnitFactor;
  final String _tickerUnitLabel;
  String _attributionText;
  final String? _statsDistanceText;
  final String? _statsDurationText;
  final String _brandText;

  /// "Made with Flymap" line on the end card. Shown only when the watermark
  /// is on, so a Pro user who removes the watermark removes this too.
  final String _madeWithText;

  Size get _size => Size(spec.width.toDouble(), spec.height.toDouble());

  /// Visible tiles for the frame at [t] (at the video's single tile level,
  /// plus parents for draw-time fallback); feed to
  /// `VideoTileStore.ensureDecoded` before painting.
  Set<TileCoord> tilesForFrame(double t) {
    final tiles = visibleTilesForPose(
      planner.transformAt(t),
      levelOverride: planner.tileLevel,
    );
    return {
      ...tiles,
      for (final tile in tiles)
        if (tile.parent != null) tile.parent!,
    };
  }

  void paintFrame(Canvas canvas, double t) {
    final wt = planner.transformAt(t);

    canvas.drawRect(
      Offset.zero & _size,
      Paint()..color = const Color(0xFF0A1626),
    );

    _drawMapPlane(canvas, wt, t);
    _drawSky(canvas, wt);
    _drawScrims(canvas);
    _drawEndpoints(canvas, wt, t);
    _drawRegionPins(canvas, wt, t);
    _drawLandingPulse(canvas, wt, t);
    _drawPlane(canvas, wt, t);
    _drawHeader(canvas, t);
    _drawDistanceTicker(canvas, t);
    if (showEndCard) _drawStatsOverlay(canvas, t);
    _drawWatermark(canvas);
    _drawAttribution(canvas, t);
  }

  /// Frees GPU-backed images owned by this renderer.
  void dispose() {
    planeSprite?.dispose();
    brandLogo?.dispose();
    _planeModel?.dispose();
  }

  /// Swaps in a different map style's tiles and its per-style styling
  /// (trail color + attribution), reusing every style-independent artefact:
  /// plane model, region artwork, brand logo and route geometry. Lets a style
  /// change skip a full session rebuild.
  void retile({
    required TileResolver tiles,
    required Color routeColor,
    required String attributionText,
  }) {
    this.tiles = tiles;
    this.routeColor = routeColor;
    if (attributionText != _attributionText) {
      _attributionText = attributionText;
      _attribution = null; // rebuild the cached layout with the new text
    }
  }

  /// Soft dark gradients along the top and bottom edges so the header,
  /// chip, watermark and attribution stay readable over bright imagery.
  void _drawScrims(Canvas canvas) {
    final topRect = Rect.fromLTWH(0, 0, _size.width, _size.height * 0.18);
    canvas.drawRect(
      topRect,
      Paint()
        ..shader = ui.Gradient.linear(topRect.topCenter, topRect.bottomCenter, [
          const Color(0x8C000000),
          const Color(0x00000000),
        ]),
    );
    final bottomRect = Rect.fromLTWH(
      0,
      _size.height * 0.84,
      _size.width,
      _size.height * 0.16,
    );
    canvas.drawRect(
      bottomRect,
      Paint()
        ..shader = ui.Gradient.linear(
          bottomRect.topCenter,
          bottomRect.bottomCenter,
          [const Color(0x00000000), const Color(0x99000000)],
        ),
    );
  }

  // --- Map plane (tiles + route), drawn under the perspective transform ---

  /// Muted earth tone under the tiles: a tile that is briefly missing (still
  /// decoding, failed download) reads as hazy terrain instead of a black
  /// hole.
  static const Color _groundFallback = Color(0xFF3A443C);

  void _drawMapPlane(Canvas canvas, WorldTransform wt, double t) {
    canvas.save();
    final mapRect = Rect.fromLTRB(
      0,
      wt.mapClipTop,
      _size.width,
      _size.height,
    );
    canvas.clipRect(mapRect);
    // Where the map runs out (past the mercator limit near the poles, or a
    // still-decoding tile), fill with a gradient instead of a flat dark
    // slab: atmosphere-haze just under the horizon fading to a muted earth
    // tone lower down. The far edge of the map then dissolves into the sky
    // rather than showing a hard dark rim.
    final fadeEnd = mapRect.top + mapRect.height * 0.45;
    canvas.drawRect(
      mapRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(mapRect.center.dx, mapRect.top),
          Offset(mapRect.center.dx, fadeEnd),
          [_skyHorizon, _groundFallback],
        ),
    );
    canvas.transform(wt.canvasMatrix.storage);

    _drawTiles(canvas, wt);
    _drawRoute(canvas, wt, t);

    canvas.restore();
  }

  void _drawTiles(Canvas canvas, WorldTransform wt) {
    final positioned = positionedTilesForPose(
      wt,
      levelOverride: planner.tileLevel,
    );

    final exact = <(PositionedTile, ui.Image)>[];
    final fallback = <(PositionedTile, ui.Image, Rect)>[];
    for (final tile in positioned) {
      final image = tiles.imageFor(tile.coord);
      if (image != null) {
        exact.add((tile, image));
        continue;
      }
      final parent = _findAncestorImage(tile.coord);
      if (parent != null) {
        fallback.add((tile, parent.image, parent.sourceRect));
      }
    }

    // Bilinear only: mipmapped filtering across ~80 tile draws per frame is
    // a large hidden GPU cost, and the haze hides far-field shimmer.
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.low;

    // Low-res stand-ins first so exact tiles paint over their edges.
    for (final (tile, image, src) in fallback) {
      canvas.drawImageRect(image, src, _inflated(tile.worldRect), paint);
    }
    for (final (tile, image) in exact) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        _inflated(tile.worldRect),
        paint,
      );
    }
  }

  /// Slight overlap between neighbours hides hairline sampling seams under
  /// the perspective transform.
  Rect _inflated(Rect rect) => rect.inflate(rect.width * 0.002);

  ({ui.Image image, Rect sourceRect})? _findAncestorImage(TileCoord coord) {
    var current = coord;
    for (var up = 1; up <= 3; up++) {
      final parent = current.parent;
      if (parent == null) return null;
      current = parent;
      final image = tiles.imageFor(current);
      if (image == null) continue;
      final span = 1 << up;
      final dx = coord.x - (current.x << up);
      final dy = coord.y - (current.y << up);
      final w = image.width / span;
      final h = image.height / span;
      // Inset slightly so neighbouring quadrants don't bleed in.
      final src = Rect.fromLTWH(dx * w, dy * h, w, h).deflate(0.5);
      return (image: image, sourceRect: src);
    }
    return null;
  }

  /// Dash-ON intervals in normalized route arc length, computed once. The
  /// dash pattern is anchored to the GEOGRAPHY: dashing the projected path
  /// per frame redistributes the gaps whenever the camera zooms (dive and
  /// outro), which reads as a crawling, "alive" line. Sized to render at
  /// ~34/26 px under the follow camera; at other zooms the dashes scale with
  /// the map, like paint on the ground.
  late final List<(double, double)> _dashRanges = _buildDashRanges();

  List<(double, double)> _buildDashRanges() {
    const earthCircumferenceKm = 40075.016686;
    final kmPerWorldPx =
        (earthCircumferenceKm * cos(route.midLat * pi / 180)) /
        (WorldTransform.tileSizePx * pow(2.0, planner.followZoom));
    final totalKm = max(route.totalKm, 1e-6);
    final dashS = max(1e-4, 34 * kmPerWorldPx / totalKm);
    final gapS = max(1e-4, 26 * kmPerWorldPx / totalKm);

    final ranges = <(double, double)>[];
    var s = 0.0;
    while (s < 1 && ranges.length < 4000) {
      ranges.add((s, min(1, s + dashS)));
      s += dashS + gapS;
    }
    return ranges;
  }

  /// Dashed trail from departure to the plane's current position; nothing is
  /// drawn ahead of the plane. Each dash is a fixed slice of the ROUTE (see
  /// [_dashRanges]): once drawn it never moves or re-gaps as the camera
  /// flies — the only change per frame is the newest dash growing behind
  /// the plane. Still one stroked path for the whole trail.
  void _drawRoute(Canvas canvas, WorldTransform wt, double t) {
    final planeProgress = planner.planeProgressAt(t);
    if (planeProgress <= 0) return;

    final trailPaint = Paint()
      ..color = routeColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final points = route.samplePoints;
    final lastIndex = points.length - 1;
    final path = Path();
    for (final (rangeStart, rangeEnd) in _dashRanges) {
      if (rangeStart >= planeProgress) break;
      final s1 = min(rangeEnd, planeProgress);
      final start = wt.worldOf(route.pointAt(rangeStart));
      path.moveTo(start.dx, start.dy);
      // Follow the route's curvature through the samples inside the dash.
      for (var i = (rangeStart * lastIndex).ceil();
          i <= (s1 * lastIndex).floor();
          i++) {
        final p = wt.worldOf(points[i]);
        path.lineTo(p.dx, p.dy);
      }
      final end = wt.worldOf(route.pointAt(s1));
      path.lineTo(end.dx, end.dy);
    }
    canvas.drawPath(path, trailPaint);
  }

  // --- Sky and haze, screen space ---

  void _drawSky(Canvas canvas, WorldTransform wt) {
    final clipTop = wt.mapClipTop;
    if (clipTop <= 0) return;

    final skyRect = Rect.fromLTRB(0, 0, _size.width, clipTop);
    canvas.drawRect(
      skyRect,
      Paint()
        ..shader = ui.Gradient.linear(skyRect.topCenter, skyRect.bottomCenter, [
          _skyTop,
          _skyHorizon,
        ]),
    );

    // Haze band feathers the hard edge where the map is clipped.
    final hazeHeight = _size.height * 0.10;
    final hazeRect = Rect.fromLTWH(0, clipTop, _size.width, hazeHeight);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = ui.Gradient.linear(
          hazeRect.topCenter,
          hazeRect.bottomCenter,
          [_skyHorizon, _skyHorizon.withValues(alpha: 0)],
        ),
    );
  }

  // --- Screen-space overlays ---

  void _drawEndpoints(Canvas canvas, WorldTransform wt, double t) {
    _drawEndpoint(
      canvas,
      wt,
      point: route.departure,
      code: flight.departure.displayCode,
      scale: planner.depMarkerScaleAt(t),
      labelToLeft: true,
    );
    // In mystery mode the arrival marker and its airport-code pill would
    // reveal the destination on the map; hold it until the reveal at
    // landing, where it pops in with the header flip and landing pulse.
    if (!mysteryDestination || t >= CameraPathPlanner.flightEnd) {
      _drawEndpoint(
        canvas,
        wt,
        point: route.arrival,
        code: flight.arrival.displayCode,
        scale: planner.arrMarkerScaleAt(t),
        labelToLeft: false,
      );
    }
  }

  void _drawEndpoint(
    Canvas canvas,
    WorldTransform wt, {
    required LatLng point,
    required String code,
    required double scale,
    required bool labelToLeft,
  }) {
    if (scale <= 0) return;
    final world = wt.worldOf(point);
    if (wt.perspectiveDepth(world) <= 0.05) return;
    final screen = wt.projectWorld(world);
    if (!(Offset.zero & _size).inflate(160).contains(screen)) return;

    final radius = 13.0 * scale;
    canvas.drawCircle(screen, radius + 3, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(screen, radius, Paint()..color = routeColor);

    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty || scale < 0.6) return;
    _drawLabelPill(canvas, anchor: screen, text: trimmed, toLeft: labelToLeft);
  }

  void _drawLabelPill(
    Canvas canvas, {
    required Offset anchor,
    required String text,
    required bool toLeft,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    const hPad = 16.0;
    const vPad = 8.0;
    const gap = 22.0;
    final width = painter.width + hPad * 2;
    final height = painter.height + vPad * 2;
    var left = toLeft ? anchor.dx - width - gap : anchor.dx + gap;
    var top = anchor.dy + gap;
    left = left.clamp(8.0, max(8.0, _size.width - width - 8));
    top = top.clamp(8.0, max(8.0, _size.height - height - 8));
    final rect = Rect.fromLTWH(left, top, width, height);

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(22));
    canvas.drawRRect(rrect, Paint()..color = _pillBackground);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _pillBorder,
    );
    painter.paint(canvas, Offset(rect.left + hPad, rect.top + vPad));
  }

  void _drawPlane(Canvas canvas, WorldTransform wt, double t) {
    // The plane sits at the departure airport from the very start, and
    // shrinks away right after touchdown so the outro shows only the route,
    // pins and markers.
    const appearStart = 0.015;
    const appearEnd = 0.05;
    const vanishStart = CameraPathPlanner.flightEnd;
    const vanishEnd = CameraPathPlanner.flightEnd + 0.04;
    if (t < appearStart || t >= vanishEnd) return;
    final appear = ((t - appearStart) / (appearEnd - appearStart)).clamp(
      0.0,
      1.0,
    );
    final vanish = ((t - vanishStart) / (vanishEnd - vanishStart)).clamp(
      0.0,
      1.0,
    );
    final presence = appear * (1 - vanish);
    if (presence <= 0) return;

    final s = planner.planeProgressAt(t);
    final position = route.pointAt(s);
    final world = wt.worldOf(position);
    if (wt.perspectiveDepth(world) <= 0.05) return;
    var screen = wt.projectWorld(world);

    // Screen-space heading from a short look-ahead along the path.
    final aheadWorld = wt.worldOf(route.pointAt(min(1, s + 0.004)));
    var direction = wt.projectWorld(aheadWorld) - screen;
    if (direction.distanceSquared < 1e-9) {
      final behindWorld = wt.worldOf(route.pointAt(max(0, s - 0.004)));
      direction = screen - wt.projectWorld(behindWorld);
    }
    var heading = direction.distanceSquared < 1e-9
        ? 0.0
        : atan2(direction.dx, -direction.dy);

    // Slow, gentle banking while cruising: the wings dip alternately (like a
    // plane settling on approach) while the whole plane bobs softly in
    // phase. No sway, no heading wiggle. Deterministic: preview == export.
    final seconds = t * spec.duration.inMilliseconds / 1000;
    final flightU = ((t - CameraPathPlanner.overviewEnd) /
            (CameraPathPlanner.flightEnd - CameraPathPlanner.overviewEnd))
        .clamp(0.0, 1.0);
    final dance = flightU <= 0 || flightU >= 1 ? 0.0 : sin(pi * flightU);
    final beat = 2 * pi * seconds * 0.45;
    final bob = sin(beat) * 4 * dance;
    final bank = sin(beat) * dance * 7 * pi / 180;

    // Altitude: the plane climbs off its ground shadow after takeoff and
    // settles back onto it at landing.
    final lift = 46 * dance;

    final scale = 0.7 + 0.3 * presence;

    final mesh = _planeMesh;
    if (mesh != null) {
      final sizePx = 250.0 * scale;
      final tiltRad = wt.pose.pitchDeg * pi / 180;
      // Shadow stays on the ground at the route point, offset like a low
      // sun; the plane flies above it.
      mesh.paintShadow(
        canvas,
        center: screen + const Offset(14, 12),
        headingRad: heading,
        tiltRad: tiltRad,
        sizePx: sizePx,
        bankRad: bank,
        opacity: 0.28 * presence,
      );
      mesh.paint(
        canvas,
        center: screen + Offset(0, bob - lift),
        headingRad: heading,
        tiltRad: tiltRad,
        sizePx: sizePx,
        bankRad: bank,
        opacity: presence,
      );
      return;
    }
    screen += Offset(0, bob - lift);

    final sprite = planeSprite;
    if (sprite == null) return;
    final width = _planeWidth * scale;
    final height = _planeHeight * scale;
    final src = Rect.fromLTWH(
      0,
      0,
      sprite.width.toDouble(),
      sprite.height.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: width,
      height: height,
    );

    canvas.save();
    canvas.translate(screen.dx, screen.dy);
    canvas.rotate(heading);
    // Plain offset shadow copy — no per-frame blur filters in the paint path.
    canvas.drawImageRect(
      sprite,
      src,
      dst.shift(const Offset(0, 10)),
      Paint()
        ..colorFilter = const ColorFilter.mode(
          Color(0x59000000),
          BlendMode.srcIn,
        ),
    );
    canvas.drawImageRect(
      sprite,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(0, 0, 0, presence),
    );
    canvas.restore();
  }

  /// Expanding pulse rings at the arrival airport as the plane lands.
  void _drawLandingPulse(Canvas canvas, WorldTransform wt, double t) {
    const start = CameraPathPlanner.flightEnd;
    const duration = 0.09;
    if (t < start || t > start + duration) return;

    final world = wt.worldOf(route.arrival);
    if (wt.perspectiveDepth(world) <= 0.05) return;
    final screen = wt.projectWorld(world);

    for (var ring = 0; ring < 2; ring++) {
      final u = ((t - start - ring * 0.025) / (duration - 0.025)).clamp(
        0.0,
        1.0,
      );
      if (u <= 0 || u >= 1) continue;
      final eased = CameraPathPlanner.easeInOutSine(u);
      canvas.drawCircle(
        screen,
        24 + eased * 110,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 * (1 - eased) + 1.5
          ..color = routeColor.withValues(alpha: 0.85 * (1 - eased)),
      );
    }
  }

  /// Distance counter under the header, ticking up as the plane flies.
  void _drawDistanceTicker(Canvas canvas, double t) {
    if (_tickerTotalKm <= 0) return;
    final s = planner.planeProgressAt(t);
    final value = _tickerTotalKm * _tickerUnitFactor * s;
    final rounded = value < 10 ? value.round() : (value / 10).round() * 10;
    final text = '${_formatThousands(rounded)} $_tickerUnitLabel';
    _paintTextLeft(
      canvas,
      text: text,
      // Same white as the city subtitle: the accent-colored counter fought
      // the header for attention.
      style: const TextStyle(
        color: Color(0xE6FFFFFF),
        fontSize: 38,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)],
      ),
      topLeft: const Offset(headerInsetX, 222),
    );
  }

  static String _formatThousands(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );

  /// Google-Maps-style pins that pop in as the plane enters each country and
  /// stay on the map — the outro zoom-out shows the whole trip decorated
  /// with them. One pin per country, labelled with its name.
  void _drawRegionPins(Canvas canvas, WorldTransform wt, double t) {
    if (!showPins) return;
    final model = regionHighlights;
    if (model == null) return;
    final s = planner.planeProgressAt(t);

    // In mystery mode, the destination country's pin (its name) would give
    // the ending away; hold it until the reveal. Only matters for
    // international routes — a domestic country pin never names the city.
    final depCountry = flight.departure.countryCode.trim().toUpperCase();
    final arrCountry = flight.arrival.countryCode.trim().toUpperCase();
    final hideArrivalCountry = mysteryDestination &&
        t < CameraPathPlanner.flightEnd &&
        arrCountry.isNotEmpty &&
        arrCountry != depCountry;

    for (final pin in model.pins) {
      if (s < pin.sPop) continue;
      if (hideArrivalCountry &&
          (pin.region.countryCode ?? '').trim().toUpperCase() == arrCountry) {
        continue;
      }
      final pop = _easeOutBackClamped(((s - pin.sPop) / 0.015).clamp(0.0, 1.0));
      if (pop <= 0) continue;

      final world = wt.worldOf(pin.anchor);
      if (wt.perspectiveDepth(world) <= 0.05) continue;
      final screen = wt.projectWorld(world);
      if (!(Offset.zero & _size).inflate(180).contains(screen)) continue;

      _drawPin(canvas, screen, pin.region, pop);
    }
  }

  static const Offset _pinHeadCenter = Offset(0, -58);
  static const double _pinHeadRadius = 34.0;

  /// Pin body path is constant — built once (Path.combine per frame is
  /// measurable CPU, and a MaskFilter blur here was a per-frame GPU
  /// render-to-texture that dominated export time).
  static final Path _pinBodyPath = Path.combine(
    PathOperation.union,
    Path()
      ..moveTo(0, 0)
      ..lineTo(-16, -46)
      ..lineTo(16, -46)
      ..close(),
    Path()
      ..addOval(Rect.fromCircle(center: _pinHeadCenter, radius: _pinHeadRadius)),
  );

  void _drawPin(
    Canvas canvas,
    Offset tip,
    RegionHighlight region,
    double scale,
  ) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.scale(scale);

    const headCenter = _pinHeadCenter;
    const headRadius = _pinHeadRadius;
    final body = _pinBodyPath;

    // Cheap offset shadow (no blur: blurred paths cost a render pass each).
    canvas.save();
    canvas.translate(3, 5);
    canvas.drawPath(body, Paint()..color = const Color(0x38000000));
    canvas.restore();
    canvas.drawPath(body, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = routeColor,
    );

    final artwork = region.artwork;
    if (artwork != null) {
      // Circular flag / region-type icon, same imagery as in-app chips.
      const artworkRadius = headRadius - 4;
      canvas.drawImageRect(
        artwork,
        Rect.fromLTWH(
          0,
          0,
          artwork.width.toDouble(),
          artwork.height.toDouble(),
        ),
        Rect.fromCircle(center: headCenter, radius: artworkRadius),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      final painter = TextPainter(
        text: TextSpan(
          text: region.emoji,
          style: const TextStyle(fontSize: 34),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          headCenter.dx - painter.width / 2,
          headCenter.dy - painter.height / 2,
        ),
      );
    }

    // Country name floating above the pin head (layout cached per region).
    final label = _pinLabelCache.putIfAbsent(
      region,
      () => TextPainter(
        text: TextSpan(
          text: region.label,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 420),
    );
    const labelHPad = 14.0;
    const labelVPad = 7.0;
    final labelRect = Rect.fromCenter(
      center: Offset(0, headCenter.dy - headRadius - 34),
      width: label.width + labelHPad * 2,
      height: label.height + labelVPad * 2,
    );
    final labelRRect = RRect.fromRectAndRadius(
      labelRect,
      Radius.circular(labelRect.height / 2),
    );
    canvas.drawRRect(labelRRect, Paint()..color = _pillBackground);
    canvas.drawRRect(
      labelRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _pillBorder,
    );
    label.paint(
      canvas,
      Offset(labelRect.left + labelHPad, labelRect.top + labelVPad),
    );
    canvas.restore();
  }

  static double _easeOutBackClamped(double u) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final x = u - 1;
    return u <= 0 ? 0 : (1 + c3 * x * x * x + c1 * x * x);
  }

  /// Constant route header, top-left: airport codes (with country flags on
  /// international flights, sky-camera style) and a city subtitle below.
  void _drawHeader(Canvas canvas, double t) {
    _ensureHeaderPainters();
    // Open ending (user-toggled mode): the destination stays a "?" until the
    // plane lands (the reveal fires with the landing pulse), then the real
    // airport shows. Off by default — the classic header shows everything.
    final revealed =
        !mysteryDestination || t >= CameraPathPlanner.flightEnd;
    (revealed ? _headerTitleRevealed : _headerTitleMystery)
        ?.paint(canvas, const Offset(headerInsetX, 96));
    (revealed ? _headerSubtitleRevealed : _headerSubtitleMystery)
        ?.paint(canvas, const Offset(headerInsetX, 168));
  }

  void _ensureHeaderPainters() {
    if (_headerTitleRevealed != null) return;

    final dep = flight.departure;
    final arr = flight.arrival;
    const shadows = [
      Shadow(color: Color(0xCC000000), blurRadius: 10),
      Shadow(color: Color(0x66000000), blurRadius: 3),
    ];
    const titleStyle = TextStyle(
      color: Color(0xFFFFFFFF),
      fontSize: 54,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
      shadows: shadows,
    );
    const subtitleStyle = TextStyle(
      color: Color(0xE6FFFFFF),
      fontSize: 34,
      fontWeight: FontWeight.w600,
      shadows: shadows,
    );

    final depCountry = dep.countryCode.trim().toUpperCase();
    final arrCountry = arr.countryCode.trim().toUpperCase();
    final isInternational =
        depCountry.isNotEmpty && arrCountry.isNotEmpty &&
        depCountry != arrCountry;

    String airportDisplay(String code, String countryCode) {
      final trimmed = code.trim().toUpperCase();
      if (!isInternational) return trimmed;
      final flag = RegionHighlightModel.flagEmoji(countryCode);
      return flag == null ? trimmed : '$flag $trimmed';
    }

    final depTitle = airportDisplay(dep.displayCode, depCountry);
    _headerTitleRevealed = _leftTextPainter(
      '$depTitle → ${airportDisplay(arr.displayCode, arrCountry)}',
      titleStyle,
    );
    // No arrival flag before the reveal — it would give the ending away.
    _headerTitleMystery = _leftTextPainter('$depTitle → ?', titleStyle);

    final depCity = RouteUtils.cityLabel(dep.city).trim();
    final arrCity = RouteUtils.cityLabel(arr.city).trim();
    // Domestic flights drop the country codes, like the sky camera overlay.
    final depCityLabel =
        isInternational ? _cityWithCountry(depCity, depCountry) : depCity;
    final arrCityLabel =
        isInternational ? _cityWithCountry(arrCity, arrCountry) : arrCity;
    if ('$depCityLabel$arrCityLabel'.trim().isEmpty) return;
    _headerSubtitleRevealed = _leftTextPainter(
      '$depCityLabel → $arrCityLabel',
      subtitleStyle,
    );
    _headerSubtitleMystery = _leftTextPainter(
      '$depCityLabel → ?',
      subtitleStyle,
    );
  }

  TextPainter _leftTextPainter(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: _size.width - headerInsetX - 48);

  static const double headerInsetX = 48;

  String _cityWithCountry(String city, String country) {
    if (city.isEmpty) return country;
    if (country.isEmpty) return city;
    return '$city, $country';
  }

  /// Constant brand watermark, TOP-right of every frame: the white logo
  /// asset when available, otherwise a text fallback.
  ///
  /// Top-right is the TikTok-safe spot: their UI covers the bottom ~20%
  /// (caption/music), the right rail from roughly mid-height down
  /// (like/comment/share), and the top ~130px (tabs/search) — a bottom-right
  /// watermark disappears under the rail the moment the video is posted.
  void _drawWatermark(Canvas canvas) {
    if (!watermarkEnabled) return;
    const padding = 40.0;
    // Top edge aligned with the header airport codes (drawn at y=96) so the
    // brand and the route title sit on the same line across the frame.
    const topInset = 96.0;
    final logo = brandLogo;
    if (logo != null && logo.width > 0 && logo.height > 0) {
      const targetWidth = 220.0;
      final targetHeight = targetWidth * logo.height / logo.width;
      final dst = Rect.fromLTWH(
        _size.width - targetWidth - padding,
        topInset,
        targetWidth,
        targetHeight,
      );
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        dst,
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = const Color(0xF2FFFFFF),
      );
      return;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: '✈ $_brandText',
        style: const TextStyle(
          color: Color(0xBFFFFFFF),
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(_size.width - painter.width - padding, topInset),
    );
  }

  void _drawStatsOverlay(Canvas canvas, double t) {
    final opacity = planner.statsOverlayOpacityAt(t);
    if (opacity <= 0) return;

    final chipRows = _layoutEndCardChips();
    final width = _size.width - 120;

    // Content strings.
    final depCode = flight.departure.displayCode.trim().toUpperCase();
    final arrCode = flight.arrival.displayCode.trim().toUpperCase();
    final depSub = _cityWithCountry(
      RouteUtils.cityLabel(flight.departure.city).trim(),
      flight.departure.countryCode.trim().toUpperCase(),
    );
    final arrSub = _cityWithCountry(
      RouteUtils.cityLabel(flight.arrival.city).trim(),
      flight.arrival.countryCode.trim().toUpperCase(),
    );
    final subtitle = (depSub.isEmpty && arrSub.isEmpty)
        ? ''
        : '$depSub → $arrSub';
    final details = <String>[
      if (_statsDistanceText != null) _statsDistanceText,
      if (_statsDurationText != null) _statsDurationText,
    ].join('   ·   ');
    // "Made with Flymap" rides with the watermark toggle: Pro users who
    // remove the watermark lose this line too.
    final showMadeWith = watermarkEnabled && _madeWithText.isNotEmpty;

    // Measure the vertical layout, then place — so the card is exactly as
    // tall as its content (codes + city/country + stats + chips + credit).
    const padTop = 34.0;
    const padBottom = 30.0;
    const titleH = 66.0;
    const subtitleH = 52.0;
    const detailsH = 54.0;
    const chipsGap = 14.0;
    const chipRowStep = 78.0;
    const madeWithGap = 18.0;
    const madeWithH = 44.0;

    var height = padTop + titleH;
    if (subtitle.isNotEmpty) height += subtitleH;
    if (details.isNotEmpty) height += detailsH;
    if (chipRows.isNotEmpty) {
      height += chipsGap + chipRows.length * chipRowStep - (chipRowStep - 58);
    }
    if (showMadeWith) height += madeWithGap + madeWithH;
    height += padBottom;

    final slide = (1 - opacity) * 60;
    final rect = Rect.fromLTWH(
      60,
      _size.height - height - 170 + slide,
      width,
      height,
    );

    canvas.save();
    // Fade the whole card as one layer so overlapping strokes don't flash.
    canvas.saveLayer(
      rect.inflate(20),
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
    );

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(36));
    canvas.drawRRect(rrect, Paint()..color = _pillBackground);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _pillBorder,
    );

    var y = rect.top + padTop;
    _paintText(
      canvas,
      text: '$depCode  →  $arrCode',
      style: const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 56,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
      center: Offset(rect.center.dx, y + titleH / 2),
    );
    y += titleH;

    if (subtitle.isNotEmpty) {
      _paintText(
        canvas,
        text: subtitle,
        style: const TextStyle(
          color: Color(0xE6FFFFFF),
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        center: Offset(rect.center.dx, y + subtitleH / 2),
      );
      y += subtitleH;
    }

    if (details.isNotEmpty) {
      _paintText(
        canvas,
        text: details,
        style: const TextStyle(
          color: Color(0xE6FFFFFF),
          fontSize: 38,
          fontWeight: FontWeight.w600,
        ),
        center: Offset(rect.center.dx, y + detailsH / 2),
      );
      y += detailsH;
    }

    if (chipRows.isNotEmpty) {
      y += chipsGap;
      for (final row in chipRows) {
        _drawEndCardChipRow(canvas, row, rect.center.dx, y);
        y += chipRowStep;
      }
      y -= chipRowStep - 58;
    }

    if (showMadeWith) {
      y += madeWithGap;
      _paintText(
        canvas,
        text: _madeWithText,
        style: const TextStyle(
          color: Color(0x99FFFFFF),
          fontSize: 26,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        center: Offset(rect.center.dx, y + madeWithH / 2),
      );
    }

    canvas.restore();
    canvas.restore();
  }

  static const double _endCardChipFontSize = 30;
  static const double _endCardChipHPad = 20;
  static const double _endCardChipGap = 16;
  static const double _endCardChipHeight = 58;
  static const double _endCardChipArtworkSize = 40;
  static const double _endCardChipArtworkGap = 10;
  static const int _maxEndCardChipRows = 4;

  String _endCardChipText(RegionChipData chip) =>
      chip.artwork == null ? '${chip.emoji} ${chip.label}' : chip.label;

  double _endCardChipLeading(RegionChipData chip) => chip.artwork == null
      ? 0
      : _endCardChipArtworkSize + _endCardChipArtworkGap;

  /// Wraps the end-card chips into measured rows that fit the card width.
  List<List<(RegionChipData, double)>> _layoutEndCardChips() {
    if (endCardChips.isEmpty) return const [];
    final maxRowWidth = _size.width - 120 - 80;
    final rows = <List<(RegionChipData, double)>>[];
    var row = <(RegionChipData, double)>[];
    var rowWidth = 0.0;
    for (final chip in endCardChips) {
      final painter = TextPainter(
        text: TextSpan(
          text: _endCardChipText(chip),
          style: const TextStyle(fontSize: _endCardChipFontSize),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final width =
          painter.width + _endCardChipHPad * 2 + _endCardChipLeading(chip);
      final needed = row.isEmpty ? width : rowWidth + _endCardChipGap + width;
      if (row.isNotEmpty && needed > maxRowWidth) {
        rows.add(row);
        row = [];
        rowWidth = 0;
        // Up to four rows so long multi-country routes still show every
        // country crossed (was two — which hid the tail of the list).
        if (rows.length == _maxEndCardChipRows) break;
      }
      rowWidth = row.isEmpty ? width : rowWidth + _endCardChipGap + width;
      row.add((chip, width));
    }
    if (row.isNotEmpty && rows.length < _maxEndCardChipRows) rows.add(row);
    return rows;
  }

  void _drawEndCardChipRow(
    Canvas canvas,
    List<(RegionChipData, double)> row,
    double centerX,
    double top,
  ) {
    final totalWidth =
        row.fold(0.0, (sum, chip) => sum + chip.$2) +
        _endCardChipGap * (row.length - 1);
    var x = centerX - totalWidth / 2;
    for (final (chip, width) in row) {
      final rect = Rect.fromLTWH(x, top, width, _endCardChipHeight);
      final rrect = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(_endCardChipHeight / 2),
      );
      canvas.drawRRect(rrect, Paint()..color = const Color(0x33FFFFFF));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _pillBorder,
      );
      final artwork = chip.artwork;
      if (artwork != null) {
        canvas.drawImageRect(
          artwork,
          Rect.fromLTWH(
            0,
            0,
            artwork.width.toDouble(),
            artwork.height.toDouble(),
          ),
          Rect.fromCenter(
            center: Offset(
              x + _endCardChipHPad + _endCardChipArtworkSize / 2,
              rect.center.dy,
            ),
            width: _endCardChipArtworkSize,
            height: _endCardChipArtworkSize,
          ),
          Paint()..filterQuality = FilterQuality.high,
        );
      }
      final painter = TextPainter(
        text: TextSpan(
          text: _endCardChipText(chip),
          style: const TextStyle(
            fontSize: _endCardChipFontSize,
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          x + _endCardChipHPad + _endCardChipLeading(chip),
          top + (_endCardChipHeight - painter.height) / 2,
        ),
      );
      x += width + _endCardChipGap;
    }
  }

  void _paintText(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required Offset center,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: _size.width - 160);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _paintTextLeft(
    Canvas canvas, {
    required String text,
    required TextStyle style,
    required Offset topLeft,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: _size.width - topLeft.dx - 48);
    painter.paint(canvas, topLeft);
  }

  void _drawAttribution(Canvas canvas, double t) {
    final painter = _attribution ??= TextPainter(
      text: TextSpan(
        text: _attributionText,
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(
      canvas,
      Offset(24, _size.height - painter.height - 20),
    );
  }
}
