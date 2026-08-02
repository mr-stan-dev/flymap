import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/domain/policy/flight_phase_policy.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/altitude_instrument.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/compass_instrument.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/instrument_telemetry.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/speed_instrument.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/instruments/temperature_instrument.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/metric_info.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/dashboard/metric_row.dart';
import 'package:flymap/utils/speed_unit_utils.dart';

class FlightInstrumentCluster extends StatefulWidget {
  const FlightInstrumentCluster({required this.gpsData, super.key});

  final GpsData? gpsData;

  @override
  State<FlightInstrumentCluster> createState() =>
      _FlightInstrumentClusterState();
}

class _FlightInstrumentClusterState extends State<FlightInstrumentCluster> {
  double? _previousSpeedMs;
  double? _previousAltitudeM;
  double? _speedDeltaKmh;
  double? _altitudeDeltaM;
  MetricTrend _speedTrend = MetricTrend.steady;
  MetricTrend _altitudeTrend = MetricTrend.steady;
  TemperatureUnit _temperatureUnit = TemperatureUnit.celsius;
  final MetricUnitsRepository _unitsRepository = MetricUnitsRepository();

  @override
  void initState() {
    super.initState();
    _primePreviousValues(widget.gpsData);
    _loadTemperatureUnit();
  }

  @override
  void didUpdateWidget(covariant FlightInstrumentCluster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gpsData != widget.gpsData) {
      _updateTrends(widget.gpsData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = InstrumentTelemetry.fromGpsData(widget.gpsData);
    final phase = FlightPhasePolicy.classify(
      speedKmh: telemetry.speedKmh,
      altitudeMeters: telemetry.altitudeMeters,
      speedDeltaKmh: _speedDeltaKmh,
      altitudeDeltaMeters: _altitudeDeltaM,
    );

    final t = context.t.flight.dashboard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MetricInfoSection(
          title: t.groundSpeed,
          body: t.groundSpeedInfoBody,
          child: GroundSpeedInstrument(
            telemetry: telemetry,
            speedTrend: _speedTrend,
            phase: phase,
          ),
        ),
        const SizedBox(height: DsSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: MetricInfoSection(
                      title: t.altitudeMsl,
                      body: t.altitudeInfoBody,
                      child: AltitudeInstrument(
                        telemetry: telemetry,
                        trend: _altitudeTrend,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DsSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: MetricInfoSection(
                      title: t.headingPanel,
                      body: t.headingInfoBody,
                      child: CompassInstrument(telemetry: telemetry),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: DsSpacing.sm),
        MetricInfoSection(
          title: t.outsideAirApprox,
          body: t.temperatureInfoBody,
          child: TemperatureInstrument(
            telemetry: telemetry,
            temperatureUnit: _temperatureUnit,
          ),
        ),
      ],
    );
  }

  void _primePreviousValues(GpsData? data) {
    _previousSpeedMs = _toMetersPerSecond(data?.speed);
    _previousAltitudeM = data?.altitude == null
        ? null
        : _toMeters(data?.altitude);
    _speedDeltaKmh = null;
    _altitudeDeltaM = null;
  }

  Future<void> _loadTemperatureUnit() async {
    final unit = await _unitsRepository.getTemperatureUnit();
    if (mounted) {
      setState(() {
        _temperatureUnit = unit;
      });
    }
  }

  void _updateTrends(GpsData? data) {
    final speedMs = _toMetersPerSecond(data?.speed);
    final altitudeM = data?.altitude == null ? null : _toMeters(data?.altitude);
    _speedDeltaKmh = _previousSpeedMs == null
        ? null
        : (speedMs - _previousSpeedMs!) * 3.6;
    _altitudeDeltaM = _previousAltitudeM == null || altitudeM == null
        ? null
        : altitudeM - _previousAltitudeM!;
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

  double _toMetersPerSecond(SpeedValue? speed) {
    return SpeedUnitUtils.toMetersPerSecond(speed);
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
