import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flymap/data/motion/motion_sample.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_palette.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_shell.dart';

/// Cabin air pressure from the barometer, shown as a bar between a pressurised
/// cruise cabin and sea level, plus a friendly "feels like" cabin altitude.
class CabinPressureInstrument extends StatelessWidget {
  const CabinPressureInstrument({
    required this.sample,
    required this.altitudeUnit,
    this.onEarPainArticleTap,
    super.key,
  });

  final MotionSample sample;

  /// 'm' or 'ft' — for the cabin-altitude hint.
  final String altitudeUnit;

  final VoidCallback? onEarPainArticleTap;

  // Bar range: low pressure (high cabin) on the left, sea level on the right.
  static const _minHpa = 700.0;
  static const _maxHpa = 1030.0;
  static const _seaLevelHpa = 1013.25;

  @override
  Widget build(BuildContext context) {
    final palette = InstrumentPalette.of(context);
    // The section is only mounted when a barometer reading exists (see
    // FlightMotionSection); guard defensively all the same.
    final pressure = sample.pressureHpa;
    if (pressure == null) return const SizedBox.shrink();

    return InstrumentPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-right is left free for the info button overlay.
          PanelLabel(context.t.flight.dashboard.cabinPressure),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pressure.round().toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: palette.primaryText,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'hPa',
                style: instrumentUnitStyle(context, palette.secondaryText),
              ),
              const Spacer(),
              Text(
                context.t.flight.dashboard.cabinPressureLikeAltitude(
                  altitude: _cabinAltitudeLabel(pressure),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.secondaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 16,
            child: CustomPaint(
              painter: _PressureBarPainter(
                progress: ((pressure - _minHpa) / (_maxHpa - _minHpa))
                    .clamp(0.0, 1.0)
                    .toDouble(),
                seaLevelProgress:
                    ((_seaLevelHpa - _minHpa) / (_maxHpa - _minHpa))
                        .clamp(0.0, 1.0)
                        .toDouble(),
                low: palette.altitudeLow,
                high: palette.altitudeHigh,
                marker: palette.primaryText,
                track: palette.track,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t.flight.dashboard.cabinPressureCruise,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.secondaryText,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                context.t.flight.dashboard.cabinPressureSeaLevel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: palette.secondaryText,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          if (onEarPainArticleTap != null) ...[
            const SizedBox(height: DsSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onEarPainArticleTap,
                child: Text(
                  context.t.flight.dashboard.cabinPressureEarPainArticle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Barometric formula → the altitude this cabin pressure corresponds to.
  String _cabinAltitudeLabel(double hpa) {
    final meters = 44330.0 * (1 - math.pow(hpa / _seaLevelHpa, 1 / 5.255));
    final clamped = meters.clamp(0.0, 40000.0).toDouble();
    if (altitudeUnit.toLowerCase() == 'ft') {
      final ft = (clamped * 3.28084 / 100).round() * 100;
      return '${_grouped(ft)} ft';
    }
    final m = (clamped / 50).round() * 50;
    return '${_grouped(m)} m';
  }

  static String _grouped(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final left = raw.length - i;
      buffer.write(raw[i]);
      if (left > 1 && left % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _PressureBarPainter extends CustomPainter {
  const _PressureBarPainter({
    required this.progress,
    required this.seaLevelProgress,
    required this.low,
    required this.high,
    required this.marker,
    required this.track,
  });

  final double progress;
  final double seaLevelProgress;
  final Color low;
  final Color high;
  final Color marker;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 1, size.width, size.height - 2),
      Radius.circular(size.height / 2),
    );
    final shader = LinearGradient(
      colors: [low, high],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(barRect, Paint()..shader = shader);

    // Faint sea-level reference tick.
    final seaX = size.width * seaLevelProgress.clamp(0.0, 1.0).toDouble();
    canvas.drawLine(
      Offset(seaX, -1),
      Offset(seaX, size.height + 1),
      Paint()
        ..color = track
        ..strokeWidth = 1.5,
    );

    // Current pressure marker.
    final x = size.width * progress.clamp(0.0, 1.0).toDouble();
    canvas.drawCircle(
      Offset(x, size.height / 2),
      size.height * 0.55,
      Paint()..color = marker,
    );
    canvas.drawCircle(
      Offset(x, size.height / 2),
      size.height * 0.55,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _PressureBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.seaLevelProgress != seaLevelProgress ||
        oldDelegate.low != low ||
        oldDelegate.high != high ||
        oldDelegate.marker != marker ||
        oldDelegate.track != track;
  }
}
