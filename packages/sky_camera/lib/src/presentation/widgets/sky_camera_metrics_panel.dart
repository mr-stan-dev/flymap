import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_telemetry_formatter.dart';

class SkyCameraMetricsPanel extends StatelessWidget {
  const SkyCameraMetricsPanel({required this.formatter, super.key});

  final SkyCameraTelemetryFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final metrics = formatter.visibleMetricDisplays;
    if (metrics.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          _SkyCameraMetricChip(
            icon: metrics[i].icon,
            iconColor: metrics[i].iconColor,
            value: metrics[i].value,
          ),
          if (i != metrics.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SkyCameraMetricChip extends StatelessWidget {
  const _SkyCameraMetricChip({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x5E0A101A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: iconColor),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
