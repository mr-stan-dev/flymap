import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_route_presentation.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_telemetry_formatter.dart';
import 'package:sky_camera/src/presentation/sky_camera_metrics_position.dart';
import 'package:sky_camera/src/presentation/sky_camera_signal_bar_metrics.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_brand_mark.dart';

class SkyCameraOverlayComposer {
  const SkyCameraOverlayComposer();

  static const _bottomGradientHeightFactor = 0.28;

  Future<Uint8List> compose({
    required Uint8List originalBytes,
    required SkyCameraOverlaySnapshot snapshot,
    required SkyCameraStrings strings,
    required SkyCameraMetricsPosition metricsPosition,
  }) async {
    final codec = await ui.instantiateImageCodec(originalBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, width, height);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, width, height),
      rect,
      Paint(),
    );

    final theme = _OverlayTheme(width: width, height: height);
    final formatter = SkyCameraTelemetryFormatter(
      snapshot: snapshot,
      strings: strings,
    );
    final visibleMetrics = formatter.visibleMetricDisplays;
    final route = SkyCameraRoutePresentation.fromSnapshot(snapshot);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, height * 0.42),
          const [Color(0xE60259DE), Color(0x000259DE)],
        ),
    );

    final bottomGradientTop = height * (1 - _bottomGradientHeightFactor);
    final bottomGradientRect = Rect.fromLTWH(
      0,
      bottomGradientTop,
      width,
      height * _bottomGradientHeightFactor,
    );
    canvas.drawRect(
      bottomGradientRect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, height),
          Offset(0, bottomGradientTop),
          const [Color(0xFF232323), Color(0x33232323), Color(0x00232323)],
          const [0.0, 0.45, 1.0],
        ),
    );

    final routeTop = theme.margin;
    final techStripHeight = formatter.shouldShowTechStrip
        ? theme.techStripHeight + theme.techStripSpacing
        : 0.0;
    if (formatter.shouldShowTechStrip) {
      _drawTechStrip(canvas, theme: theme, formatter: formatter, top: routeTop);
    }
    _drawRouteHeader(
      canvas,
      route: route,
      theme: theme,
      top: routeTop + techStripHeight,
    );

    if (visibleMetrics.isNotEmpty) {
      _drawMetricsPanel(
        canvas,
        theme: theme,
        metricsPosition: metricsPosition,
        specs: visibleMetrics,
      );
    }

    await _drawBrand(canvas, theme: theme);

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(image.width, image.height);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    rendered.dispose();
    picture.dispose();
    codec.dispose();
    if (bytes == null) {
      throw StateError('Could not encode the camera overlay.');
    }
    return bytes.buffer.asUint8List();
  }

  Future<void> _drawBrand(Canvas canvas, {required _OverlayTheme theme}) async {
    final logo = await _loadBrandLogo();
    if (logo == null) return;
    final src = Rect.fromLTWH(
      0,
      0,
      logo.width.toDouble(),
      logo.height.toDouble(),
    );
    final targetHeight = theme.brandLogoHeight;
    final targetWidth = targetHeight * (logo.width / logo.height);
    final dst = Rect.fromLTWH(
      theme.width - theme.margin - targetWidth,
      theme.brandTop,
      targetWidth,
      targetHeight,
    );
    canvas.drawImageRect(logo, src, dst, Paint());
    logo.dispose();
  }

  Future<ui.Image?> _loadBrandLogo() async {
    try {
      final data = await rootBundle.load(SkyCameraBrandMark.brandAssetPath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  void _drawRouteHeader(
    Canvas canvas, {
    required SkyCameraRoutePresentation route,
    required _OverlayTheme theme,
    required double top,
  }) {
    if (route.originDisplay.isEmpty &&
        route.destinationDisplay.isEmpty &&
        route.subtitle == null) {
      return;
    }
    final codeStyle = TextStyle(
      color: Colors.white,
      fontSize: theme.routeFontSize,
      fontWeight: FontWeight.w800,
      height: 1.05,
      shadows: const [
        Shadow(color: Color(0x42000000), blurRadius: 12, offset: Offset(0, 3)),
      ],
    );
    final arrowStyle = codeStyle.copyWith(fontSize: theme.arrowFontSize);

    final originPainter = _textPainter(route.originDisplay, codeStyle);
    final arrowPainter = _textPainter('→', arrowStyle);
    final destinationPainter = _textPainter(
      route.destinationDisplay,
      codeStyle,
    );

    final baseLeft = theme.margin;
    originPainter.paint(canvas, Offset(baseLeft, top));
    final arrowLeft = baseLeft + originPainter.width + theme.routeInlineGap;
    arrowPainter.paint(
      canvas,
      Offset(arrowLeft, top - (theme.routeFontSize * 0.04)),
    );
    final destinationLeft =
        arrowLeft + arrowPainter.width + theme.routeInlineGap;
    destinationPainter.paint(canvas, Offset(destinationLeft, top));

    if (route.subtitle == null) return;
    _drawText(
      canvas,
      text: route.subtitle!,
      offset: Offset(baseLeft, top + theme.routeSubtitleTopOffset),
      fontSize: theme.routeSubtitleFontSize,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.94),
      maxWidth: theme.width - (theme.margin * 2),
    );
  }

  void _drawTechStrip(
    Canvas canvas, {
    required _OverlayTheme theme,
    required SkyCameraTelemetryFormatter formatter,
    required double top,
  }) {
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.88),
      fontSize: theme.techStripFontSize,
      fontWeight: FontWeight.w600,
    );
    final dateIcon = _iconPainter(
      Icons.calendar_today_rounded,
      size: theme.techStripIconSize,
      color: Colors.white70,
    );
    final globeIcon = _iconPainter(
      Icons.public_rounded,
      size: theme.techStripIconSize,
      color: Colors.white70,
    );
    final datePainter = _textPainter(formatter.dateLabel, style);
    final coordinatesPainter = _textPainter(
      formatter.coordinatesDirectionalLabel,
      style,
      maxWidth: theme.width * 0.46,
    );
    final gpsLabelPainter = _textPainter('GPS', style);
    final contentBottom = top + theme.techStripHeight;
    final contentTop = contentBottom - datePainter.height;
    final iconTop = contentBottom - dateIcon.height;
    var left = theme.margin;
    dateIcon.paint(canvas, Offset(left, iconTop));
    left += dateIcon.width + theme.techStripIconGap;
    datePainter.paint(canvas, Offset(left, contentTop));
    left += datePainter.width + theme.techStripSectionGap;
    globeIcon.paint(canvas, Offset(left, iconTop));
    left += globeIcon.width + theme.techStripIconGap;
    coordinatesPainter.paint(canvas, Offset(left, contentTop));
    final gpsLabelLeft = theme.width - theme.margin - gpsLabelPainter.width;
    gpsLabelPainter.paint(canvas, Offset(gpsLabelLeft, contentTop));
    _drawSignalBars(
      canvas,
      strength: formatter.gpsSignalStrength,
      right: gpsLabelLeft - theme.techStripIconGap,
      bottom: top + theme.techStripHeight,
      theme: theme,
    );
  }

  void _drawMetricsPanel(
    Canvas canvas, {
    required _OverlayTheme theme,
    required SkyCameraMetricsPosition metricsPosition,
    required List<SkyCameraMetricDisplay> specs,
  }) {
    final layouts = [
      for (final spec in specs)
        _buildMetricChipLayout(theme: theme, spec: spec),
    ];
    final maxWidth = layouts.fold<double>(
      0,
      (current, layout) => current > layout.width ? current : layout.width,
    );
    final panelHeight =
        (theme.metricChipHeight * layouts.length) +
        (theme.metricGap * (layouts.length - 1));
    final origin =
        metricsPosition.resolve(
          containerSize: Size(
            theme.width - (theme.margin * 2),
            theme.height - (theme.margin * 2),
          ),
          childSize: Size(maxWidth, panelHeight),
        ) +
        Offset(theme.margin, theme.margin);
    for (var i = 0; i < layouts.length; i++) {
      _drawMetricChip(
        canvas,
        theme: theme,
        left: origin.dx,
        top: origin.dy + (i * (theme.metricChipHeight + theme.metricGap)),
        layout: layouts[i],
      );
    }
  }

  _MetricChipLayout _buildMetricChipLayout({
    required _OverlayTheme theme,
    required SkyCameraMetricDisplay spec,
  }) {
    final valuePainter = _textPainter(
      spec.value,
      TextStyle(
        color: Colors.white,
        fontSize: theme.metricFontSize,
        fontWeight: FontWeight.w800,
      ),
    );
    final iconPainter = _iconPainter(
      spec.icon,
      size: theme.metricIconSize,
      color: spec.iconColor,
    );
    final width =
        theme.metricHorizontalPadding * 2 +
        iconPainter.width +
        theme.metricIconGap +
        valuePainter.width;
    return _MetricChipLayout(
      width: width,
      valuePainter: valuePainter,
      iconPainter: iconPainter,
    );
  }

  void _drawMetricChip(
    Canvas canvas, {
    required _OverlayTheme theme,
    required double left,
    required double top,
    required _MetricChipLayout layout,
  }) {
    final rect = Rect.fromLTWH(left, top, layout.width, theme.metricChipHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(theme.metricChipRadius)),
      Paint()..color = const Color(0x5E0A101A),
    );
    final iconTop = rect.top + ((rect.height - layout.iconPainter.height) / 2);
    layout.iconPainter.paint(
      canvas,
      Offset(rect.left + theme.metricHorizontalPadding, iconTop),
    );
    final textTop = rect.top + ((rect.height - layout.valuePainter.height) / 2);
    layout.valuePainter.paint(
      canvas,
      Offset(
        rect.left +
            theme.metricHorizontalPadding +
            layout.iconPainter.width +
            theme.metricIconGap,
        textTop,
      ),
    );
  }

  void _drawSignalBars(
    Canvas canvas, {
    required SkyCameraGpsSignalStrength strength,
    required double right,
    required double bottom,
    required _OverlayTheme theme,
  }) {
    const signalScale = SkyCameraSignalBarMetrics.scale;
    const heights = SkyCameraSignalBarMetrics.heights;
    final activeBars = switch (strength) {
      SkyCameraGpsSignalStrength.none => 0,
      SkyCameraGpsSignalStrength.bad => 1,
      SkyCameraGpsSignalStrength.poor => 2,
      SkyCameraGpsSignalStrength.good => 3,
    };
    final activeColor = switch (strength) {
      SkyCameraGpsSignalStrength.none => Colors.white.withValues(alpha: 0.2),
      SkyCameraGpsSignalStrength.bad => const Color(0xFFFF4D4F),
      SkyCameraGpsSignalStrength.poor => const Color(0xFFFFC72C),
      SkyCameraGpsSignalStrength.good => const Color(0xFF7CFF2B),
    };
    final barWidth = theme.techStripBarWidth * signalScale;
    final barGap = theme.techStripBarGap * signalScale;
    final totalWidth =
        (barWidth * heights.length) + (barGap * (heights.length - 1));
    var left = right - totalWidth;
    for (var i = 0; i < heights.length; i++) {
      final height = heights[i] * theme.scale * signalScale;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, bottom - height, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = i < activeBars
              ? activeColor
              : Colors.white.withValues(alpha: 0.2),
      );
      left += barWidth + barGap;
    }
    if (strength == SkyCameraGpsSignalStrength.none) {
      final indicatorSize = heights.last * theme.scale * signalScale;
      final center = Offset(
        right - (totalWidth / 2),
        bottom - (indicatorSize / 2),
      );
      final spinnerRect = Rect.fromCenter(
        center: center,
        width: indicatorSize,
        height: indicatorSize,
      );
      canvas.drawArc(
        spinnerRect,
        -math.pi / 2,
        math.pi * 1.45,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * theme.scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  TextPainter _iconPainter(
    IconData icon, {
    required double size,
    required Color color,
  }) {
    return _textPainter(
      String.fromCharCode(icon.codePoint),
      TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
  }

  TextPainter _textPainter(String text, TextStyle style, {double? maxWidth}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: maxWidth == null ? null : '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    return painter;
  }

  void _drawText(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? maxWidth,
  }) {
    final painter = _textPainter(
      text,
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: 1.2,
      ),
      maxWidth: maxWidth,
    );
    painter.paint(canvas, offset);
  }
}

class _OverlayTheme {
  const _OverlayTheme({required this.width, required this.height});

  final double width;
  final double height;

  static const _referenceWidth = 393.0;

  double get scale => width / _referenceWidth;

  double get margin => 18 * scale;
  double get routeFontSize => 34 * scale;
  double get arrowFontSize => 34 * scale;
  double get routeSubtitleFontSize => 17 * scale;
  double get routeInlineGap => 10 * scale;
  double get routeSubtitleTopOffset => 48 * scale;
  double get techStripHeight => 18 * scale;
  double get techStripSpacing => 18 * scale;
  double get techStripFontSize => 12 * scale;
  double get techStripIconSize => 14 * scale;
  double get techStripIconGap => 6 * scale;
  double get techStripSectionGap => 18 * scale;
  double get techStripBarWidth => 4 * scale;
  double get techStripBarGap => 2 * scale;
  double get metricChipHeight => 46 * scale;
  double get metricChipRadius => 14 * scale;
  double get metricHorizontalPadding => 14 * scale;
  double get metricFontSize => 18 * scale;
  double get metricIconSize => 21 * scale;
  double get metricIconGap => 10 * scale;
  double get metricGap => 12 * scale;
  double get brandLogoHeight => 28 * scale;
  double get brandTop => height - margin - brandLogoHeight;
}

class _MetricChipLayout {
  const _MetricChipLayout({
    required this.width,
    required this.valuePainter,
    required this.iconPainter,
  });

  final double width;
  final TextPainter valuePainter;
  final TextPainter iconPainter;
}
