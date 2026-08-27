import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_map_painter.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_wind_presentation.dart';
import 'package:flymap/ui/screens/share_flight/widgets/map/share_image_painter.dart';

/// Everything the share card needs as plain strings — resolved from i18n
/// and formatters at the call site so the renderer stays context-free.
class WeatherShareData {
  const WeatherShareData({
    required this.headline,
    required this.subtitle,
    required this.departure,
    required this.arrival,
    required this.attribution,
    required this.watermark,
  });

  /// "BRS → KRK"
  final String headline;

  /// "FR6221 · Aug 4" (or just the date).
  final String subtitle;
  final WeatherShareAirport departure;
  final WeatherShareAirport arrival;

  /// Provider credit, transformation disclosure and license URL. It is burned
  /// into every exported image/video because those files travel outside the
  /// app and must remain attributable on their own.
  final String attribution;

  /// "flymap.app"
  final String watermark;
}

class WeatherShareAirport {
  const WeatherShareAirport({
    required this.code,
    required this.city,
    required this.countryCode,
    required this.countryFlag,
    required this.symbol,
    required this.temperatureText,
    required this.timeText,
    required this.dateText,
    this.utcOffsetText,
    this.windText,
    this.windFilledBars = 0,
    this.windTone = WeatherWindTone.normal,
    this.precipitationText,
  });

  final String code;
  final String city;
  final String countryCode;
  final String countryFlag;
  final WeatherSymbolKind symbol;

  /// "21°" (dash when unknown).
  final String temperatureText;

  final String timeText;
  final String dateText;
  final String? utcOffsetText;

  /// Same compact numeric wind value as the live collapsed airport card.
  final String? windText;
  final int windFilledBars;
  final WeatherWindTone windTone;
  final String? precipitationText;
}

/// Renders the shareable weather story card (1080x1920) fully offscreen:
/// dark branded background, route headline, two collapsed airport forecast
/// rows, the cloud map as hero (via [WeatherMapPainter], so it matches the
/// on-screen animation at any [renderFrame] progress), attribution and a
/// watermark. One renderer serves both the static image and every video frame.
class WeatherShareRenderer {
  WeatherShareRenderer({
    required this.data,
    required this.projectedRoute,
    required this.cloudFrames,
    required this.routeKm,
    this.mapImage,
    this.logoImage,
    this.weatherIcons = const <WeatherSymbolKind, ui.Image>{},
  });

  static const double width = 1080;
  static const double height = 1920;
  static const double _margin = 64;
  static const double _airportCardsTop = 330;
  static const double _airportCardHeight = 208;
  static const double _airportCardGap = 28;
  static const double _mapTop = 822;

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

  /// Weather SVGs rasterized once and reused by the static card and all video
  /// frames. Missing entries fall back to the symbol's native emoji.
  final Map<WeatherSymbolKind, ui.Image> weatherIcons;

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
    _drawAttribution(canvas);
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
      const Offset(_margin, 122),
      fontSize: 76,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      maxWidth: width - 2 * _margin,
    );
    _text(
      canvas,
      data.subtitle,
      const Offset(_margin, 228),
      fontSize: 42,
      fontWeight: FontWeight.w600,
      color: ShareImagePainter.routeColor,
      maxWidth: width - 2 * _margin,
    );
  }

  void _drawAirportCards(Canvas canvas) {
    const cardWidth = width - 2 * _margin;
    _drawAirportCard(
      canvas,
      data.departure,
      const Rect.fromLTWH(
        _margin,
        _airportCardsTop,
        cardWidth,
        _airportCardHeight,
      ),
    );
    _drawAirportCard(
      canvas,
      data.arrival,
      const Rect.fromLTWH(
        _margin,
        _airportCardsTop + _airportCardHeight + _airportCardGap,
        cardWidth,
        _airportCardHeight,
      ),
    );
  }

  void _drawAirportCard(Canvas canvas, WeatherShareAirport airport, Rect rect) {
    final card = RRect.fromRectAndRadius(rect, const Radius.circular(34));
    canvas.drawRRect(card, Paint()..color = const Color(0xFF292929));
    canvas.drawRRect(
      card,
      Paint()
        ..color = const Color(0xFF4A4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    const pad = 32.0;
    final x = rect.left + pad;
    final right = rect.right - pad;
    const summaryWidth = 380.0;
    final summaryLeft = right - summaryWidth;
    final locationWidth = summaryLeft - x - 28;

    // Same compact hierarchy as the live collapsed card: airport and city on
    // the left, schedule beneath, and a protected weather column on the right.
    final codeWidth = _text(
      canvas,
      airport.code,
      Offset(x, rect.top + 30),
      fontSize: 44,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFE7E7E7),
      maxWidth: 130,
    );

    var locationX = x + codeWidth + 18;
    final hasFlag = airport.countryFlag.isNotEmpty;
    if (hasFlag) {
      final flagWidth = _text(
        canvas,
        airport.countryFlag,
        Offset(locationX, rect.top + 36),
        fontSize: 28,
        maxWidth: 46,
      );
      locationX += flagWidth + 10;
    }
    _text(
      canvas,
      airport.countryCode.isEmpty
          ? airport.city
          : '${airport.city} · ${airport.countryCode}',
      Offset(locationX, rect.top + 36),
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFE7E7E7),
      maxWidth: locationWidth - (locationX - x),
    );

    final timeAndDate = [
      '${airport.timeText}'
          '${airport.utcOffsetText == null ? '' : ' ${airport.utcOffsetText}'}',
      airport.dateText,
    ].join(' · ');
    _text(
      canvas,
      timeAndDate,
      Offset(x, rect.top + 108),
      fontSize: 28,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF9B9B9B),
      maxWidth: locationWidth,
    );

    const iconSize = 132.0;
    final iconRect = Rect.fromLTWH(
      summaryLeft,
      rect.top + 36,
      iconSize,
      iconSize,
    );
    final weatherIcon = weatherIcons[airport.symbol];
    if (weatherIcon != null) {
      canvas.drawImageRect(
        weatherIcon,
        Rect.fromLTWH(
          0,
          0,
          weatherIcon.width.toDouble(),
          weatherIcon.height.toDouble(),
        ),
        iconRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      _text(
        canvas,
        airport.symbol.emoji,
        Offset(summaryLeft + 12, rect.top + 54),
        fontSize: 72,
        maxWidth: iconSize,
      );
    }

    final detailsX = summaryLeft + iconSize + 18;
    _text(
      canvas,
      airport.temperatureText,
      Offset(detailsX, rect.top + 30),
      fontSize: 60,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFE7E7E7),
      maxWidth: right - detailsX,
    );

    final wind = airport.windText;
    if (wind != null) {
      final windColor = switch (airport.windTone) {
        WeatherWindTone.normal => const Color(0xFF9B9B9B),
        WeatherWindTone.warning => Colors.amber.shade800,
        WeatherWindTone.strong => Colors.deepOrange.shade600,
      };
      for (var bar = 0; bar < 3; bar++) {
        final barHeight = 16.0 + bar * 7;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              detailsX + bar * 10,
              rect.top + 142 - barHeight,
              6,
              barHeight,
            ),
            const Radius.circular(3),
          ),
          Paint()
            ..color = bar < airport.windFilledBars
                ? windColor
                : const Color(0x409B9B9B),
        );
      }
      _text(
        canvas,
        wind,
        Offset(detailsX + 40, rect.top + 108),
        fontSize: 26,
        fontWeight: airport.windTone == WeatherWindTone.normal
            ? FontWeight.w400
            : FontWeight.w700,
        color: windColor,
        maxWidth: right - detailsX - 38,
      );
    }

    final precipitation = airport.precipitationText;
    if (precipitation != null) {
      _text(
        canvas,
        precipitation,
        Offset(detailsX + 40, rect.top + 158),
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF9B9B9B),
        maxWidth: right - detailsX - 38,
      );
    }
  }

  void _drawMap(Canvas canvas, double progress) {
    const mapSize = width - 2 * _margin;
    const rect = Rect.fromLTWH(_margin, _mapTop, mapSize, mapSize);
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

  void _drawAttribution(Canvas canvas) {
    final painter = TextPainter(
      text: TextSpan(
        text: data.attribution,
        style: const TextStyle(
          color: Color(0xBFFFFFFF),
          fontSize: 20,
          fontWeight: FontWeight.w500,
          height: 1.25,
        ),
      ),
      maxLines: 2,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: 700);
    painter.paint(canvas, Offset(_margin, height - painter.height - 34));
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
