import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/compass_rose_painter.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/metric_row.dart';

class FlightCompassWidget extends StatefulWidget {
  const FlightCompassWidget({required this.gpsData, super.key});

  final GpsData? gpsData;

  @override
  State<FlightCompassWidget> createState() => _FlightCompassWidgetState();
}

class _FlightCompassWidgetState extends State<FlightCompassWidget> {
  double? _previousSpeedMs;
  double? _previousAltitudeM;
  MetricTrend _speedTrend = MetricTrend.steady;
  MetricTrend _altitudeTrend = MetricTrend.steady;

  @override
  void initState() {
    super.initState();
    _primePreviousValues(widget.gpsData);
  }

  @override
  void didUpdateWidget(covariant FlightCompassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gpsData != widget.gpsData) {
      _updateTrends(widget.gpsData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final course = widget.gpsData?.course ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 48;
        final compassSize = math.max(220.0, math.min(340.0, maxWidth - 16));

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLabeledMetric(
                      context,
                      label: t.flight.info.speed,
                      child: _buildSpeedIndicator(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildLabeledMetric(
                      context,
                      label: t.flight.info.altitude,
                      child: _buildAltitudeIndicator(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.flight.dashboard.aircraftHeading,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.25,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: compassSize,
              height: compassSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.05),
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
                  Transform.rotate(
                    angle: -(course * (math.pi / 180)),
                    child: CustomPaint(
                      size: Size(compassSize, compassSize),
                      painter: CompassRosePainter(
                        color: colorScheme.onSurface,
                        accentColor: colorScheme.primary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.airplanemode_active,
                    size: compassSize * 0.21,
                    color: colorScheme.primary,
                  ),
                  Positioned(
                    bottom: compassSize * 0.2,
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
                        t.flight.dashboard.headingShort(
                          heading: course.toStringAsFixed(0),
                        ),
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
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  void _primePreviousValues(GpsData? data) {
    _previousSpeedMs = _toMetersPerSecond(data?.speed);
    _previousAltitudeM = _toMeters(data?.altitude);
  }

  void _updateTrends(GpsData? data) {
    final speedMs = _toMetersPerSecond(data?.speed);
    final altitudeM = _toMeters(data?.altitude);
    _speedTrend = _trend(
      previous: _previousSpeedMs,
      current: speedMs,
      epsilon: 0.3,
    );
    _altitudeTrend = _trend(
      previous: _previousAltitudeM,
      current: altitudeM,
      epsilon: 1.0,
    );
    _previousSpeedMs = speedMs;
    _previousAltitudeM = altitudeM;
  }

  MetricTrend _trend({
    required double? previous,
    required double? current,
    required double epsilon,
  }) {
    if (previous == null || current == null) return MetricTrend.steady;
    final delta = current - previous;
    if (delta > epsilon) return MetricTrend.up;
    if (delta < -epsilon) return MetricTrend.down;
    return MetricTrend.steady;
  }

  Widget _buildSpeedIndicator(BuildContext context) {
    final speed = widget.gpsData?.speed ?? const SpeedValue(0, 'km/h');
    return FlightMetricRow(
      value: speed.value.toStringAsFixed(0),
      unit: speed.unit,
      color: Theme.of(context).colorScheme.primary,
      trend: _speedTrend,
      showName: false,
    );
  }

  Widget _buildAltitudeIndicator(BuildContext context) {
    final altitude = widget.gpsData?.altitude ?? const AltitudeValue(0, 'ft');
    return FlightMetricRow(
      value: altitude.value.toStringAsFixed(0),
      unit: altitude.unit,
      color: Theme.of(context).colorScheme.secondary,
      trend: _altitudeTrend,
      showName: false,
    );
  }

  Widget _buildLabeledMetric(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  double _toMetersPerSecond(SpeedValue? speed) {
    if (speed == null) return 0;
    switch (speed.unit.toLowerCase()) {
      case 'm/s':
        return speed.value;
      case 'kt':
      case 'kts':
      case 'kn':
        return speed.value * 0.514444;
      case 'mph':
        return speed.value * 0.44704;
      case 'km/h':
      default:
        return speed.value / 3.6;
    }
  }

  double _toMeters(AltitudeValue? altitude) {
    if (altitude == null) return 0;
    switch (altitude.unit.toLowerCase()) {
      case 'm':
        return altitude.value;
      case 'ft':
      default:
        return altitude.value * 0.3048;
    }
  }
}
