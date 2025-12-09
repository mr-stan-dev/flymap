import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/gps_not_granted_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/gps_off_state.dart';
import 'package:flymap/ui/screens/flight/widgets/bottom_sheet/flight_status/searching_gps_view.dart';
import 'package:flymap/ui/theme/app_colours.dart';

class TabGPSData extends StatelessWidget {
  const TabGPSData({required this.state, super.key});

  final FlightScreenLoaded state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state.gpsStatus) {
      case GpsStatus.off:
        return const GpsOffState();
      case GpsStatus.permissionsNotGranted:
        return const GpsNotGrantedState();
      case GpsStatus.searching:
        return const SearchingGpsView();
      case GpsStatus.gpsActive:
      case GpsStatus.weakSignal:
        return _CompassView(
          gpsData: state.gpsData,
        );
    }
  }
}

class _CompassView extends StatelessWidget {
  const _CompassView({required this.gpsData});

  final GpsData? gpsData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final course = gpsData?.course ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(child: _buildSpeedIndicator(context)),
              const SizedBox(width: 8),
              Expanded(child: _buildAltitudeIndicator(context)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.05),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
            gradient: RadialGradient(
              colors: [
                colorScheme.surface,
                colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.8, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Compass Rose (Ticks and Directions)
              Transform.rotate(
                angle: -(course * (math.pi / 180)),
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: _CompassPainter(
                    color: colorScheme.onSurface,
                    accentColor: colorScheme.primary,
                  ),
                ),
              ),
              // Fixed Airplane
              Icon(
                Icons.airplanemode_active,
                size: 64,
                color: colorScheme.primary,
              ),
              // Course Text
              Positioned(
                bottom: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${course.toStringAsFixed(0)}°',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSpeedIndicator(BuildContext context) {
    final speed = gpsData?.speed ?? const SpeedValue(0, 'km/h');
    return _SimpleMetricRow(
      name: 'SPEED',
      value: speed.value.toStringAsFixed(0),
      unit: speed.unit,
      color: AppColoursCommon.accentBlue,
    );
  }

  Widget _buildAltitudeIndicator(BuildContext context) {
    final altitude = gpsData?.altitude ?? const AltitudeValue(0, 'ft');
    return _SimpleMetricRow(
      name: 'ALTITUDE',
      value: altitude.value.toStringAsFixed(0),
      unit: altitude.unit,
      color: Colors.purple,
    );
  }
}

class _SimpleMetricRow extends StatelessWidget {
  final String name;
  final String value;
  final String unit;
  final Color color;

  const _SimpleMetricRow({
    required this.name,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark 
        ? color.withOpacity(0.1) 
        : color.withOpacity(0.05);
    final borderColor = isDark 
        ? color.withOpacity(0.3) 
        : color.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _CompassPainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tickLength = 10.0;
    final majorTickLength = 15.0;

    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final majorPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw ticks
    for (int i = 0; i < 360; i += 5) {
      final isMajor = i % 90 == 0;
      final isSemiMajor = i % 30 == 0;
      final angle = (i - 90) * (math.pi / 180); // -90 to start at top

      final currentTickLength = isMajor
          ? majorTickLength + 5
          : isSemiMajor
              ? majorTickLength
              : tickLength;
              
      final p1 = Offset(
        center.dx + (radius - currentTickLength - 10) * math.cos(angle),
        center.dy + (radius - currentTickLength - 10) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 10) * math.cos(angle),
        center.dy + (radius - 10) * math.sin(angle),
      );

      canvas.drawLine(p1, p2, isMajor || isSemiMajor ? majorPaint : paint);

      // Draw Cardinal Directions
      if (isMajor) {
        String label = '';
        switch (i) {
          case 0:
            label = 'N';
            break;
          case 90:
            label = 'E';
            break;
          case 180:
            label = 'S';
            break;
          case 270:
            label = 'W';
            break;
        }

        textPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            color: i == 0 ? accentColor : color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        
        // Position text inside the ticks
        final textRadius = radius - 45;
        final textOffset = Offset(
          center.dx + textRadius * math.cos(angle) - textPainter.width / 2,
          center.dy + textRadius * math.sin(angle) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
