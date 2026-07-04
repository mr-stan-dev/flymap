import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_telemetry_formatter.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_signal_bars.dart';

class SkyCameraTechStrip extends StatelessWidget {
  const SkyCameraTechStrip({required this.formatter, super.key});

  final SkyCameraTelemetryFormatter formatter;

  @override
  Widget build(BuildContext context) {
    if (!formatter.shouldShowTechStrip) {
      return const SizedBox.shrink();
    }
    final textStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.88),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      shadows: const [
        Shadow(color: Color(0x42000000), blurRadius: 8, offset: Offset(0, 2)),
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.calendar_today_rounded,
          size: 14,
          color: Colors.white70,
        ),
        const SizedBox(width: 6),
        Text(formatter.dateLabel, style: textStyle),
        const SizedBox(width: 18),
        const Icon(Icons.public_rounded, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            formatter.coordinatesDirectionalLabel,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        SkyCameraSignalBars(
          key: const Key('sky_camera.gps_signal_bars'),
          strength: formatter.gpsSignalStrength,
          showSearchingOverlay:
              formatter.gpsSignalStrength == SkyCameraGpsSignalStrength.none,
        ),
        const SizedBox(width: 6),
        Text('GPS', style: textStyle),
      ],
    );
  }
}
