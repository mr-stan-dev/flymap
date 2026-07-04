import 'package:flutter/material.dart';
import 'package:sky_camera/src/presentation/formatters/sky_camera_telemetry_formatter.dart';
import 'package:sky_camera/src/presentation/sky_camera_signal_bar_metrics.dart';

class SkyCameraSignalBars extends StatelessWidget {
  const SkyCameraSignalBars({
    required this.strength,
    this.inactiveColor = const Color(0x33FFFFFF),
    this.barWidth = SkyCameraSignalBarMetrics.barWidth,
    this.barGap = SkyCameraSignalBarMetrics.barGap,
    this.scale = SkyCameraSignalBarMetrics.scale,
    this.showSearchingOverlay = false,
    super.key,
  }) : assert(scale > 0);

  final SkyCameraGpsSignalStrength strength;
  final Color inactiveColor;
  final double barWidth;
  final double barGap;
  final double scale;
  final bool showSearchingOverlay;

  @override
  Widget build(BuildContext context) {
    final heights = [
      for (final height in SkyCameraSignalBarMetrics.heights) height * scale,
    ];
    final scaledBarWidth = barWidth * scale;
    final scaledBarGap = barGap * scale;
    final activeBars = switch (strength) {
      SkyCameraGpsSignalStrength.none => 0,
      SkyCameraGpsSignalStrength.bad => 1,
      SkyCameraGpsSignalStrength.poor => 2,
      SkyCameraGpsSignalStrength.good => 3,
    };
    final activeColor = switch (strength) {
      SkyCameraGpsSignalStrength.none => inactiveColor,
      SkyCameraGpsSignalStrength.bad => const Color(0xFFFF4D4F),
      SkyCameraGpsSignalStrength.poor => const Color(0xFFFFC72C),
      SkyCameraGpsSignalStrength.good => const Color(0xFF7CFF2B),
    };
    final totalWidth =
        (scaledBarWidth * heights.length) +
        (scaledBarGap * (heights.length - 1));
    final maxHeight = heights.last;
    return SizedBox(
      width: maxHeight,
      height: maxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: totalWidth,
              height: maxHeight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < heights.length; i++) ...[
                    Container(
                      width: scaledBarWidth,
                      height: heights[i],
                      decoration: BoxDecoration(
                        color: i < activeBars ? activeColor : inactiveColor,
                        borderRadius: BorderRadius.circular(2 * scale),
                      ),
                    ),
                    if (i != heights.length - 1) SizedBox(width: scaledBarGap),
                  ],
                ],
              ),
            ),
          ),
          if (showSearchingOverlay)
            IgnorePointer(
              child: SizedBox(
                width: maxHeight,
                height: maxHeight,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5 * scale,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.42),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
