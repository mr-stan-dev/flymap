import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:flymap/ui/screens/share_flight/widgets/card/config/share_image_card_config.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Header of the home flight card. With a cached route-map image it renders
/// a 4:3 satellite band with the route drawn live, a scrim fading into the
/// card color, and the title/subtitle over the scrim. Without an image
/// (legacy flights, offline first launch) it renders the plain text header —
/// identical to the pre-imagery card — and lazily fetches the image for the
/// next build.
class HomeFlightCardMapHeader extends StatefulWidget {
  const HomeFlightCardMapHeader({
    required this.flight,
    required this.cardColor,
    required this.title,
    required this.subtitle,
    required this.showProCrown,
    required this.menuButton,
    super.key,
  });

  final Flight flight;

  /// Resolved card background color; the scrim fades into it so the image
  /// blends seamlessly with the content below (including the in-progress
  /// tint).
  final Color cardColor;
  final String title;
  final String subtitle;
  final bool showProCrown;
  final Widget menuButton;

  @override
  State<HomeFlightCardMapHeader> createState() =>
      _HomeFlightCardMapHeaderState();
}

class _HomeFlightCardMapHeaderState extends State<HomeFlightCardMapHeader> {
  /// The share card's plane asset, decoded once and shared by all cards.
  static Future<ui.Image?>? _planeImageFuture;

  File? _imageFile;
  ui.Image? _planeImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
    _loadPlaneImage();
  }

  Future<void> _loadPlaneImage() async {
    _planeImageFuture ??= _decodePlaneAsset();
    final image = await _planeImageFuture;
    if (!mounted || image == null) return;
    setState(() => _planeImage = image);
  }

  static Future<ui.Image?> _decodePlaneAsset() async {
    try {
      final data = await rootBundle.load(ShareImagePainter.planeAssetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      return (await codec.getNextFrame()).image;
    } catch (_) {
      return null;
    }
  }

  /// Cache-only: the image is fetched once at flight creation; the card
  /// never triggers network. Flights without a cached image (created before
  /// the feature, or whose creation-time fetch failed) keep the plain
  /// header.
  Future<void> _loadImage() async {
    if (_routePoints(widget.flight).length < 2) return;
    final file = await RouteMapImageStore.cachedCardImage(widget.flight.id);
    if (!mounted || file == null) return;
    setState(() => _imageFile = file);
  }

  /// Same fallback rule as the share pipeline: full waypoints when present,
  /// otherwise the straight airport-to-airport pair.
  static List<LatLng> _routePoints(Flight flight) {
    final waypoints = flight.waypoints;
    if (waypoints.length >= 2) return waypoints;
    return [flight.departure.latLon, flight.arrival.latLon];
  }

  @override
  Widget build(BuildContext context) {
    final file = _imageFile;
    if (file == null) return _plainHeader(context);
    return _mapHeader(context, file);
  }

  /// Pre-imagery layout, byte-for-byte: title row with the menu, subtitle
  /// underneath.
  Widget _plainHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(context),
                if (widget.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _subtitleRow(context),
                ],
              ],
            ),
          ),
          widget.menuButton,
        ],
      ),
    );
  }

  /// In light mode, the fraction of the image height shown: a translucent
  /// white scrim over dark satellite imagery looks muddy, so light mode
  /// shows the image scrim-free with the title on solid card color below —
  /// and crops the image's bottom padding zone (reserved for the dark-mode
  /// scrim) so the taller layout carries no empty map.
  static const double _lightModeImageFraction =
      (RouteMapImageStore.cardHeight - 60) / RouteMapImageStore.cardHeight;

  Widget _mapHeader(BuildContext context, File file) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseLayers = <Widget>[
      Image.file(file, fit: BoxFit.cover),
      CustomPaint(
        painter: _RouteOverlayPainter(
          points: _routePoints(widget.flight),
          routeKm: widget.flight.route.displayDistanceKm.toDouble(),
          planeImage: _planeImage,
        ),
      ),
    ];

    if (!isDark) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _lightModeImageFraction,
                child: AspectRatio(
                  aspectRatio:
                      RouteMapImageStore.cardWidth /
                      RouteMapImageStore.cardHeight,
                  child: Stack(fit: StackFit.expand, children: baseLayers),
                ),
              ),
            ),
          ),
          _plainHeader(context),
        ],
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      child: AspectRatio(
        aspectRatio:
            RouteMapImageStore.cardWidth / RouteMapImageStore.cardHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ...baseLayers,
            // Scrim: image melts into the card color behind the title
            // (dark-on-dark blends cleanly; light mode avoids this overlay
            // entirely).
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.cardColor.withValues(alpha: 0),
                        widget.cardColor,
                      ],
                      stops: const [0, 0.82],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 56,
              bottom: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(context),
                  if (widget.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _subtitleRow(context),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Material(
                color: Colors.black.withValues(alpha: 0.30),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 22),
                  child: widget.menuButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context) {
    return Text(
      widget.title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _subtitleRow(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (widget.showProCrown) ...[
          const Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: DsBrandColors.proAmber,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            widget.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Draws the route over the cached map image using the SAME visual language
/// as the share card ([ShareImagePainter]): the stylized dashed cyan arc
/// between the endpoints and white-ringed endpoint dots, scaled down
/// proportionally to the card. The endpoints come from projecting the route
/// through the deterministic card viewport (the image and paint area share
/// an aspect ratio, so a uniform scale maps image to widget coordinates).
class _RouteOverlayPainter extends CustomPainter {
  _RouteOverlayPainter({
    required this.points,
    required this.routeKm,
    required this.planeImage,
  });

  final List<LatLng> points;
  final double routeKm;
  final ui.Image? planeImage;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.isEmpty) return;
    final viewport = RouteMapImageStore.cardViewport(points);
    final scale = size.width / RouteMapImageStore.cardWidth;
    final offsets = StaticRouteMap.projectRoute(
      points: points,
      viewport: viewport,
    ).map((p) => Offset(p.x * scale, p.y * scale)).toList(growable: false);
    if (offsets.length < 2) return;

    final start = offsets.first;
    final end = offsets.last;
    // Scale the share card's stroke/dash/dot sizes by the width ratio so the
    // card reads as a miniature of the share card.
    final k = size.width / ShareImageCardConfig.width;

    // Same smoothed real-geometry path as the share card (stylized arc only
    // for endpoint-only routes); spacing scales with the thumbnail size.
    final path = ShareImagePainter.buildRoutePath(
      offsets,
      routeKm: routeKm,
      minPointSpacing: 8.0 * k,
    );
    final routePaint = Paint()
      ..color = ShareImagePainter.routeColor
      ..strokeWidth = ShareImagePainter.routeStrokeWidth * k
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dashLength = ShareImagePainter.routeDashLength * k;
    final dashGap = ShareImagePainter.routeDashGap * k;

    // Mid-route plane in a dashed-line gap, exactly like the share card.
    final plane = planeImage;
    final metrics = path.computeMetrics().toList(growable: false);
    if (plane != null && metrics.isNotEmpty) {
      final metric = metrics.first;
      final midOffset = metric.length * 0.5;
      final gapCenter =
          (midOffset + ShareImagePainter.planeGapCenterForwardBias * k).clamp(
            0.0,
            metric.length,
          );
      final halfGap = ShareImagePainter.planeGapLength * k / 2;
      final gapStart = max(0.0, gapCenter - halfGap);
      final gapEnd = min(metric.length, gapCenter + halfGap);
      if (gapStart > 0) {
        _drawDashedPath(
          canvas,
          metric.extractPath(0, gapStart),
          routePaint,
          dashLength: dashLength,
          dashGap: dashGap,
        );
      }
      if (gapEnd < metric.length) {
        _drawDashedPath(
          canvas,
          metric.extractPath(gapEnd, metric.length),
          routePaint,
          dashLength: dashLength,
          dashGap: dashGap,
        );
      }
      final tangent = metric.getTangentForOffset(midOffset);
      if (tangent != null) {
        _drawPlane(canvas, plane, tangent.position, tangent.vector, k);
      }
    } else {
      _drawDashedPath(
        canvas,
        path,
        routePaint,
        dashLength: dashLength,
        dashGap: dashGap,
      );
    }

    for (final endpoint in [start, end]) {
      canvas.drawCircle(
        endpoint,
        ShareImagePainter.endpointOuterRadius * k,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        endpoint,
        ShareImagePainter.endpointInnerRadius * k,
        Paint()..color = ShareImagePainter.routeColor,
      );
    }
  }

  /// Mirrors [ShareImagePainter]'s plane drawing (shadow pass + rotated
  /// image), with every dimension scaled by [k].
  void _drawPlane(
    Canvas canvas,
    ui.Image image,
    Offset position,
    Offset direction,
    double k,
  ) {
    if (!direction.dx.isFinite || !direction.dy.isFinite) return;
    if (direction.distanceSquared == 0) return;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    // Clockwise bearing from north; the asset faces "up".
    final heading = atan2(direction.dx, -direction.dy);
    canvas.rotate(heading);

    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: 42.0 * k,
      height: 56.0 * k,
    );
    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    canvas.drawImageRect(
      image,
      src,
      dst.shift(Offset(0, 3 * k)),
      Paint()
        ..colorFilter = const ColorFilter.mode(Colors.black38, BlendMode.srcIn)
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 3 * k, sigmaY: 3 * k),
    );
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dashLength,
    required double dashGap,
  }) {
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : dashGap;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteOverlayPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.routeKm != routeKm ||
        oldDelegate.planeImage != planeImage;
  }
}
