import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_map_painter.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';

/// Everything the share card needs as plain strings — resolved from i18n
/// and formatters at the call site so the renderer stays context-free.
class WeatherShareData {
  const WeatherShareData({
    required this.headline,
    required this.subtitle,
    required this.departure,
    required this.arrival,
    required this.watermark,
  });

  /// "BRS → KRK"
  final String headline;

  /// "FR6221 · Aug 4" (or just the date).
  final String subtitle;
  final WeatherShareAirport departure;
  final WeatherShareAirport arrival;

  /// "flymap.app"
  final String watermark;
}

class WeatherShareAirport {
  const WeatherShareAirport({
    required this.label,
    required this.code,
    required this.city,
    required this.emoji,
    required this.temperatureText,
    this.timeText,
    this.windText,
  });

  /// "DEPARTURE" / "ARRIVAL".
  final String label;
  final String code;
  final String city;
  final String emoji;

  /// "21°" (dash when unknown).
  final String temperatureText;

  /// Local wall-clock ("16:10"); null for date-only flights — the noon
  /// estimate is never displayed.
  final String? timeText;

  /// "💨 12 m/s"; null when wind is unknown.
  final String? windText;
}

/// Renders the shareable weather story card (1080x1920) fully offscreen:
/// dark branded background, route headline, the two airport forecast
/// blocks, the cloud map as hero (via [WeatherMapPainter], so it matches
/// the on-screen animation exactly at any [renderFrame] progress), the
/// verdict line and a watermark. One renderer serves both the static image
/// and every video frame.
class WeatherShareRenderer {
  WeatherShareRenderer({
    required this.data,
    required this.projectedRoute,
    required this.cloudFrames,
    required this.routeKm,
    this.mapImage,
    this.logoImage,
  });

  static const double width = 1080;
  static const double height = 1920;
  static const double _margin = 64;

  final WeatherShareData data;

  /// Route offsets in the square 540 weather viewport (the painter scales).
  final List<Offset> projectedRoute;
  final List<ui.Image> cloudFrames;
  final double routeKm;

  /// Satellite map for the hero region (retina, ~1080px); gradient
  /// fallback when null.
  final ui.Image? mapImage;

  /// White brand logo drawn as the corner watermark; text fallback when null.
  final ui.Image? logoImage;

  /// Renders one frame. [pixelRatio] scales the OUTPUT resolution without
  /// touching the layout (video frames render at a fraction of the card's
  /// logical size for speed; the static image stays full-size).
  Future<ui.Image> renderFrame(double progress, {double pixelRatio = 1}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(width, height);

    canvas.scale(pixelRatio);
    _drawBackground(canvas, size);
    _drawHeader(canvas);
    _drawAirportCards(canvas);
    _drawMap(canvas, progress);
    _drawWatermark(canvas);

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (width * pixelRatio).round(),
      (height * pixelRatio).round(),
    );
    picture.dispose();
    return image;
  }

  void _drawBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0C1626), Color(0xFF1A3350)],
        ).createShader(Offset.zero & size),
    );
  }

  void _drawHeader(Canvas canvas) {
    _text(
      canvas,
      data.headline,
      const Offset(_margin, 120),
      fontSize: 72,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      maxWidth: width - 2 * _margin,
    );
    _text(
      canvas,
      data.subtitle,
      const Offset(_margin, 214),
      fontSize: 40,
      fontWeight: FontWeight.w600,
      color: ShareImagePainter.routeColor,
      maxWidth: width - 2 * _margin,
    );
  }

  void _drawAirportCards(Canvas canvas) {
    const top = 320.0;
    const cardHeight = 360.0;
    const gap = 24.0;
    const cardWidth = (width - 2 * _margin - gap) / 2;
    _drawAirportCard(
      canvas,
      data.departure,
      const Rect.fromLTWH(_margin, top, cardWidth, cardHeight),
    );
    _drawAirportCard(
      canvas,
      data.arrival,
      const Rect.fromLTWH(
        _margin + cardWidth + gap,
        top,
        cardWidth,
        cardHeight,
      ),
    );
  }

  void _drawAirportCard(Canvas canvas, WeatherShareAirport airport, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    const pad = 28.0;
    final x = rect.left + pad;
    final innerWidth = rect.width - 2 * pad;

    final labelLine = airport.timeText == null
        ? airport.label.toUpperCase()
        : '${airport.label.toUpperCase()} · ${airport.timeText}';
    _text(
      canvas,
      labelLine,
      Offset(x, rect.top + 34),
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: Colors.white60,
      letterSpacing: 1.2,
      maxWidth: innerWidth,
    );

    _text(
      canvas,
      airport.code,
      Offset(x, rect.top + 92),
      fontSize: 56,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      maxWidth: innerWidth,
    );

    _text(
      canvas,
      airport.city,
      Offset(x, rect.top + 170),
      fontSize: 26,
      color: Colors.white60,
      maxWidth: innerWidth,
    );

    // Weather emoji + temperature.
    final rowY = rect.top + 222;
    final emojiWidth = _text(
      canvas,
      airport.emoji,
      Offset(x, rowY),
      fontSize: 56,
      maxWidth: innerWidth,
    );
    _text(
      canvas,
      airport.temperatureText,
      Offset(x + emojiWidth + 18, rowY + 4),
      fontSize: 50,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      maxWidth: innerWidth - emojiWidth - 18,
    );

    // Wind (below the temperature).
    final wind = airport.windText;
    if (wind != null) {
      _text(
        canvas,
        wind,
        Offset(x, rect.top + 300),
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        maxWidth: innerWidth,
      );
    }
  }

  void _drawMap(Canvas canvas, double progress) {
    const mapSize = width - 2 * _margin;
    const rect = Rect.fromLTWH(_margin, 750, mapSize, mapSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(36));

    canvas.save();
    canvas.clipRRect(rrect);
    final map = mapImage;
    if (map != null) {
      // Cover-fit the (square) map image.
      canvas.drawImageRect(
        map,
        Rect.fromLTWH(0, 0, map.width.toDouble(), map.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16324F), Color(0xFF3E6C99)],
          ).createShader(rect),
      );
    }
    // Same scrim as the on-screen card.
    canvas.drawRect(rect, Paint()..color = const Color(0x1F000000));

    canvas.translate(rect.left, rect.top);
    WeatherMapPainter(
      projectedRoute: projectedRoute,
      cloudFrames: cloudFrames,
      routeKm: routeKm,
      departureCode: data.departure.code,
      arrivalCode: data.arrival.code,
      showClouds: true,
      planeProgress: progress,
    ).paint(canvas, const Size(mapSize, mapSize));
    canvas.restore();
  }

  /// Brand watermark, bottom-right — the white logo asset (matching the
  /// flight-video and sky-camera share cards), with a text fallback.
  void _drawWatermark(Canvas canvas) {
    const padding = 32.0;
    final logo = logoImage;
    if (logo != null && logo.width > 0 && logo.height > 0) {
      // Height-constrained so it tucks into the strip below the verdict
      // banner (which spans the card's full bottom width) instead of
      // clipping it.
      const targetHeight = 58.0;
      final targetWidth = targetHeight * logo.width / logo.height;
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        Rect.fromLTWH(
          width - targetWidth - padding,
          height - targetHeight - padding,
          targetWidth,
          targetHeight,
        ),
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = const Color(0xF2FFFFFF),
      );
      return;
    }

    final painter = TextPainter(
      text: TextSpan(
        text: data.watermark,
        style: const TextStyle(
          color: Color(0xBFFFFFFF),
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        width - painter.width - padding,
        height - painter.height - padding,
      ),
    );
  }

  /// Draws a single line, ellipsized to [maxWidth]; returns painted width.
  double _text(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required double maxWidth,
    FontWeight fontWeight = FontWeight.w400,
    Color color = Colors.white,
    double letterSpacing = 0,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: letterSpacing,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
      // Fixed size — the card must never follow the device's font-scale
      // accessibility setting (this is a rendered image/video, not live UI).
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
    return painter.width;
  }
}
