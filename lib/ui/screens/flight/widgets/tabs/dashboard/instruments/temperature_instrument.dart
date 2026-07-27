import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/policy/outside_temperature_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_palette.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_shell.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_telemetry.dart';

class TemperatureInstrument extends StatelessWidget {
  const TemperatureInstrument({
    required this.telemetry,
    required this.temperatureUnit,
    super.key,
  });

  final InstrumentTelemetry telemetry;
  final TemperatureUnit temperatureUnit;

  @override
  Widget build(BuildContext context) {
    final palette = InstrumentPalette.of(context);
    final available = OutsideTemperaturePolicy.isAvailable(
      altitudeMeters: telemetry.altitudeMeters,
    );
    final estimate = telemetry.outsideTemperatureEstimate;
    final tempCelsius = estimate.celsius;
    final displayTemp = _displayTemperature(tempCelsius, temperatureUnit);
    final progress = ((tempCelsius + 60) / 80).clamp(0.0, 1.0).toDouble();
    final temperatureColor = _temperatureColor(palette, progress);

    return InstrumentPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PanelLabel(context.t.flight.dashboard.outsideAirApprox),
              const SizedBox(width: 8),
              Spacer(),
              Icon(
                Icons.ac_unit_rounded,
                color: palette.secondaryText,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 2),
          if (!available) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                context.t.flight.dashboard.temperatureAvailableAfter(
                  threshold: _availabilityThresholdLabel(
                    telemetry.altitudeUnit,
                  ),
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '${displayTemp.value}°${displayTemp.unitLabel}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: temperatureColor,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 18,
              child: CustomPaint(
                painter: _TemperatureBarPainter(
                  progress: progress,
                  low: palette.temperatureLow,
                  mid: palette.temperatureMid,
                  high: palette.temperatureHigh,
                  marker: palette.temperatureMarker,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t.flight.dashboard.temperatureApproxHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.secondaryText,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemperatureBarPainter extends CustomPainter {
  const _TemperatureBarPainter({
    required this.progress,
    required this.low,
    required this.mid,
    required this.high,
    required this.marker,
  });

  final double progress;
  final Color low;
  final Color mid;
  final Color high;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 1, size.width, size.height - 2),
      Radius.circular(size.height / 2),
    );
    final shader = LinearGradient(
      colors: [low, mid, high],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(barRect, Paint()..shader = shader);

    final x = size.width * progress.clamp(0.0, 1.0).toDouble();
    final markerPaint = Paint()
      ..color = marker
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), markerPaint);
  }

  @override
  bool shouldRepaint(covariant _TemperatureBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.low != low ||
        oldDelegate.mid != mid ||
        oldDelegate.high != high ||
        oldDelegate.marker != marker;
  }
}

Color _temperatureColor(InstrumentPalette palette, double progress) {
  if (progress <= 0.5) {
    return Color.lerp(
          palette.temperatureLow,
          palette.temperatureMid,
          progress * 2,
        ) ??
        palette.temperatureLow;
  }
  return Color.lerp(
        palette.temperatureMid,
        palette.temperatureHigh,
        (progress - 0.5) * 2,
      ) ??
      palette.temperatureMid;
}

_DisplayTemperature _displayTemperature(
  double celsius,
  TemperatureUnit temperatureUnit,
) {
  if (temperatureUnit == TemperatureUnit.fahrenheit) {
    return _DisplayTemperature(
      value: (celsius * 9 / 5 + 32).round(),
      unitLabel: 'F',
    );
  }
  return _DisplayTemperature(value: celsius.round(), unitLabel: 'C');
}

class _DisplayTemperature {
  const _DisplayTemperature({required this.value, required this.unitLabel});

  final int value;
  final String unitLabel;
}

String _availabilityThresholdLabel(String altitudeUnit) {
  if (altitudeUnit.toLowerCase() == 'm') return '2,000m';
  return '6,500ft';
}
