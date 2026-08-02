import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flymap/data/motion/motion_sample.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_palette.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_shell.dart';

/// Full felt g-force shown as a 180° aviation-style gauge with a peak-hold
/// marker. The magnitude is orientation-independent, so this reads correctly
/// however the phone is held — no calibration required.
class GForceInstrument extends StatelessWidget {
  const GForceInstrument({
    required this.sample,
    required this.onResetPeak,
    super.key,
  });

  final MotionSample sample;

  /// Called when the user taps the PEAK chip to clear the held maximum.
  final VoidCallback onResetPeak;

  /// Gauge spans 0..2 g so 1.0 g (rest) sits at the top-center of the arc.
  static const _scaleMaxG = 2.0;

  @override
  Widget build(BuildContext context) {
    final palette = InstrumentPalette.of(context);
    // Display the low-passed value so a shaky hand doesn't jitter the gauge.
    final displayG = sample.smoothedTotalG;
    final peakG = sample.peakG;
    final g = displayG.clamp(0.0, _scaleMaxG).toDouble();
    final gColor = _gColor(palette, displayG);
    final weightPercent = ((displayG - 1.0) * 100).round();

    return InstrumentPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top-right is left free for the info button overlay.
          PanelLabel(context.t.flight.dashboard.gForce),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 260,
              height: 116,
              child: CustomPaint(
                painter: _GaugePainter(
                  progress: g / _scaleMaxG,
                  peakProgress: (peakG / _scaleMaxG).clamp(0.0, 1.0).toDouble(),
                  needleColor: gColor,
                  peakColor: _gColor(palette, peakG),
                  track: palette.track,
                  tickColor: palette.secondaryText,
                ),
                child: Align(
                  alignment: const Alignment(0, 0.34),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        sample.hasMotion ? displayG.toStringAsFixed(2) : '—',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              color: palette.primaryText,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'g',
                        style: instrumentUnitStyle(
                          context,
                          palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PeakChip(
                peakG: peakG,
                color: palette.secondaryText,
                onReset: onResetPeak,
              ),
              const Spacer(),
              if (sample.hasMotion)
                Text(
                  weightPercent == 0
                      ? '0%'
                      : '${weightPercent > 0 ? '+' : ''}$weightPercent%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: gColor,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _gColor(InstrumentPalette palette, double g) {
    // Floating (<1 g) reads cool; normal is calm green; heavy climbs to alert.
    const calm = Color(0xFF2FBF71);
    const warn = Color(0xFFF5A623);
    const alert = Color(0xFFEB5757);
    if (g <= 1.0) {
      final t = ((g - 0.6) / 0.4).clamp(0.0, 1.0).toDouble();
      return Color.lerp(palette.altitudeLow, calm, t)!;
    }
    if (g <= 1.5) {
      final t = ((g - 1.0) / 0.5).clamp(0.0, 1.0).toDouble();
      return Color.lerp(calm, warn, t)!;
    }
    final t = ((g - 1.5) / 0.5).clamp(0.0, 1.0).toDouble();
    return Color.lerp(warn, alert, t)!;
  }
}

class _PeakChip extends StatelessWidget {
  const _PeakChip({
    required this.peakG,
    required this.color,
    required this.onReset,
  });

  final double peakG;
  final Color color;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onReset,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.t.flight.dashboard.gForcePeakLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${peakG.toStringAsFixed(2)} g',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.refresh_rounded, size: 15, color: color),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.progress,
    required this.peakProgress,
    required this.needleColor,
    required this.peakColor,
    required this.track,
    required this.tickColor,
  });

  final double progress;
  final double peakProgress;
  final Color needleColor;
  final Color peakColor;
  final Color track;
  final Color tickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.height * 0.16;
    final center = Offset(size.width / 2, size.height * 1.04);
    final radius = size.width * 0.4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = math.pi;
    const sweep = math.pi;

    // Track.
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Filled progress up to the current g value.
    canvas.drawArc(
      rect,
      start,
      sweep * progress.clamp(0.0, 1.0).toDouble(),
      false,
      Paint()
        ..color = needleColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    // Ticks at 0.5, 1.0, 1.5 g (progress 0.25 / 0.5 / 0.75); emphasise 1.0.
    for (final tick in const [0.25, 0.5, 0.75]) {
      final emphasised = tick == 0.5;
      final angle = start + sweep * tick;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - stroke * (emphasised ? 1.15 : 0.75));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = tickColor.withValues(alpha: emphasised ? 0.9 : 0.4)
          ..strokeWidth = emphasised ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // Peak-hold marker.
    final peakAngle = start + sweep * peakProgress.clamp(0.0, 1.0).toDouble();
    final peakPoint =
        center + Offset(math.cos(peakAngle), math.sin(peakAngle)) * radius;
    // Coloured by the peak's own g level (not the current value), so a high
    // past peak stays visibly "hot" even while the needle sits back at rest.
    canvas.drawCircle(
      peakPoint,
      stroke * 0.42,
      Paint()..color = peakColor,
    );
    canvas.drawCircle(
      peakPoint,
      stroke * 0.42,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Needle.
    final needleAngle = start + sweep * progress.clamp(0.0, 1.0).toDouble();
    final needleTip =
        center + Offset(math.cos(needleAngle), math.sin(needleAngle)) *
            (radius - stroke * 0.2);
    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = needleColor
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.peakProgress != peakProgress ||
        oldDelegate.needleColor != needleColor ||
        oldDelegate.peakColor != peakColor ||
        oldDelegate.track != track ||
        oldDelegate.tickColor != tickColor;
  }
}
