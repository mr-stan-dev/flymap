import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:latlong2/latlong.dart' as ll;

class MapDebugGpsProvider {
  MapDebugGpsProvider({
    this.tick = const Duration(milliseconds: 250),
    this.baseSpeedKmh = 820,
  });

  static const _routeDeviationKm = 10.0;

  final Duration tick;
  final double baseSpeedKmh;
  final ll.Distance _distance = const ll.Distance();

  Timer? _timer;
  List<ll.LatLng> _points = const [];
  List<double> _segmentLengthsKm = const [];
  double _totalDistanceKm = 0;
  double _progressKm = 0;
  int _speedMultiplier = 1;
  int _playbackGeneration = 0;
  ValueChanged<GpsData>? _onUpdate;
  VoidCallback? _onDone;

  bool get isPlaying => _timer != null;
  bool get hasRoute => _points.length >= 2 && _totalDistanceKm > 0;
  int get speedMultiplier => _speedMultiplier;

  void loadRoute(List<ll.LatLng> routePoints) {
    pause();
    _points = routePoints.length >= 2
        ? List<ll.LatLng>.unmodifiable(routePoints)
        : const [];
    _segmentLengthsKm = _buildSegmentLengthsKm(_points);
    _totalDistanceKm = _segmentLengthsKm.fold(0.0, (a, b) => a + b);
    _progressKm = 0;
  }

  void setSpeedMultiplier(int multiplier) {
    if (multiplier <= 0) return;
    _speedMultiplier = multiplier;
  }

  void play({required ValueChanged<GpsData> onUpdate, VoidCallback? onDone}) {
    if (!hasRoute || isPlaying) return;
    _onUpdate = onUpdate;
    _onDone = onDone;
    _emitCurrent();
    final generation = ++_playbackGeneration;
    _timer = Timer.periodic(tick, (_) => _tick(generation));
  }

  void pause() {
    _playbackGeneration++;
    _timer?.cancel();
    _timer = null;
  }

  void restart({
    bool autoplay = true,
    required ValueChanged<GpsData> onUpdate,
    VoidCallback? onDone,
  }) {
    if (!hasRoute) return;
    pause();
    _onUpdate = onUpdate;
    _onDone = onDone;
    _progressKm = 0;
    _emitCurrent();
    if (autoplay) {
      final generation = ++_playbackGeneration;
      _timer = Timer.periodic(tick, (_) => _tick(generation));
    }
  }

  void dispose() {
    pause();
  }

  void _tick(int generation) {
    if (generation != _playbackGeneration) return;
    final deltaHours = tick.inMilliseconds / Duration.millisecondsPerHour;
    // Coordinate progression speed is intentionally decoupled from telemetry
    // values. Multiplier changes only route traversal speed.
    final deltaKm = baseSpeedKmh * _speedMultiplier * deltaHours;
    _progressKm = (_progressKm + deltaKm).clamp(0.0, _totalDistanceKm);
    _emitCurrent();

    if (_progressKm >= _totalDistanceKm) {
      pause();
      if (generation != _playbackGeneration - 1) return;
      _onDone?.call();
    }
  }

  void _emitCurrent() {
    final ratio = _progressRatio();
    final telemetry = _telemetryAtRatio(ratio);
    final routePosition = _samplePointAtDistanceKm(_progressKm);
    final lookAhead = (_progressKm + 8).clamp(0.0, _totalDistanceKm);
    final routeNextPosition = _samplePointAtDistanceKm(lookAhead);
    final routeHeading = _bearingDegrees(routePosition, routeNextPosition);
    final deviationKm = _routeDeviationForRatio(ratio);
    final position = _offsetPoint(
      routePosition,
      bearingDegrees: routeHeading + 90.0,
      distanceKm: deviationKm,
    );
    final nextPosition = _offsetPoint(
      routeNextPosition,
      bearingDegrees: routeHeading + 90.0,
      distanceKm: deviationKm,
    );
    final heading = _bearingDegrees(position, nextPosition);

    _onUpdate?.call(
      GpsData(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: AltitudeValue(telemetry.altitudeMeters, 'm'),
        speed: SpeedValue(telemetry.speedKmh, 'km/h'),
        course: heading,
        accuracy: 5,
      ),
    );
  }

  double _progressRatio() {
    if (_totalDistanceKm <= 0) return 0.0;
    return (_progressKm / _totalDistanceKm).clamp(0.0, 1.0);
  }

  _SimTelemetry _telemetryAtRatio(double ratio) {
    // Broadly realistic envelope for passenger jet:
    // taxi -> takeoff roll -> climb -> cruise -> descent -> approach/landing
    if (ratio < 0.02) {
      final t = (ratio / 0.02).clamp(0.0, 1.0);
      return _SimTelemetry(
        speedKmh: _lerp(15, 35, t),
        altitudeMeters: _lerp(0, 80, t),
      );
    }
    if (ratio < 0.06) {
      final t = ((ratio - 0.02) / 0.04).clamp(0.0, 1.0);
      return _SimTelemetry(
        speedKmh: _lerp(35, 300, _smoothstep(t)),
        altitudeMeters: _lerp(80, 900, _smoothstep(t)),
      );
    }
    if (ratio < 0.25) {
      final t = ((ratio - 0.06) / 0.19).clamp(0.0, 1.0);
      return _SimTelemetry(
        speedKmh: _lerp(300, baseSpeedKmh, _smoothstep(t)),
        altitudeMeters: _lerp(900, 10800, _smoothstep(t)),
      );
    }
    if (ratio < 0.75) {
      final wobble = math.sin(ratio * math.pi * 8) * 18;
      return _SimTelemetry(
        speedKmh: baseSpeedKmh + wobble,
        altitudeMeters: 10800 + (math.sin(ratio * math.pi * 6) * 120),
      );
    }
    if (ratio < 0.93) {
      final t = ((ratio - 0.75) / 0.18).clamp(0.0, 1.0);
      return _SimTelemetry(
        speedKmh: _lerp(baseSpeedKmh, 420, _smoothstep(t)),
        altitudeMeters: _lerp(10800, 1300, _smoothstep(t)),
      );
    }
    final t = ((ratio - 0.93) / 0.07).clamp(0.0, 1.0);
    return _SimTelemetry(
      speedKmh: _lerp(420, 45, _smoothstep(t)),
      altitudeMeters: _lerp(1300, 0, _smoothstep(t)),
    );
  }

  double _smoothstep(double t) => t * t * (3 - (2 * t));
  double _lerp(double from, double to, double t) => from + (to - from) * t;

  List<double> _buildSegmentLengthsKm(List<ll.LatLng> points) {
    if (points.length < 2) return const [];
    final lengths = <double>[];
    for (var i = 0; i < points.length - 1; i++) {
      final km = _distance.distance(points[i], points[i + 1]) / 1000;
      lengths.add(km.isFinite ? km : 0);
    }
    return List<double>.unmodifiable(lengths);
  }

  ll.LatLng _samplePointAtDistanceKm(double distanceKm) {
    if (_points.isEmpty) return const ll.LatLng(0, 0);
    if (_points.length == 1 || distanceKm <= 0) return _points.first;

    var traversedKm = 0.0;
    for (var i = 0; i < _segmentLengthsKm.length; i++) {
      final segmentKm = _segmentLengthsKm[i];
      final segmentEndKm = traversedKm + segmentKm;
      if (distanceKm <= segmentEndKm || i == _segmentLengthsKm.length - 1) {
        if (segmentKm <= 0) return _points[i + 1];
        final t = ((distanceKm - traversedKm) / segmentKm).clamp(0.0, 1.0);
        final start = _points[i];
        final end = _points[i + 1];
        return ll.LatLng(
          start.latitude + (end.latitude - start.latitude) * t,
          _interpolateLongitudeShortestPath(start.longitude, end.longitude, t),
        );
      }
      traversedKm = segmentEndKm;
    }
    return _points.last;
  }

  double _interpolateLongitudeShortestPath(
    double fromLon,
    double toLon,
    double t,
  ) {
    var delta = toLon - fromLon;
    if (delta > 180.0) {
      delta -= 360.0;
    } else if (delta < -180.0) {
      delta += 360.0;
    }
    return _normalizeLongitude(fromLon + delta * t);
  }

  double _normalizeLongitude(double lon) {
    var normalized = lon;
    while (normalized > 180.0) {
      normalized -= 360.0;
    }
    while (normalized < -180.0) {
      normalized += 360.0;
    }
    return normalized;
  }

  double _bearingDegrees(ll.LatLng from, ll.LatLng to) {
    if (from.latitude == to.latitude && from.longitude == to.longitude) {
      return 0;
    }
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        (math.cos(lat1) * math.sin(lat2)) -
        (math.sin(lat1) * math.cos(lat2) * math.cos(dLon));
    final raw = _radToDeg(math.atan2(y, x));
    return (raw + 360) % 360;
  }

  double _routeDeviationForRatio(double ratio) {
    // Keep departure/arrival exact and only drift off-route during cruise.
    if (ratio <= 0.06 || ratio >= 0.93) return 0.0;
    if (ratio < 0.18) {
      final t = ((ratio - 0.06) / 0.12).clamp(0.0, 1.0);
      return _routeDeviationKm * _smoothstep(t);
    }
    if (ratio > 0.82) {
      final t = ((0.93 - ratio) / 0.11).clamp(0.0, 1.0);
      return _routeDeviationKm * _smoothstep(t);
    }
    return _routeDeviationKm;
  }

  ll.LatLng _offsetPoint(
    ll.LatLng origin, {
    required double bearingDegrees,
    required double distanceKm,
  }) {
    if (!distanceKm.isFinite || distanceKm == 0) return origin;

    const earthRadiusKm = 6371.0;
    final angularDistance = distanceKm / earthRadiusKm;
    final bearingRad = _degToRad(bearingDegrees);
    final lat1 = _degToRad(origin.latitude);
    final lon1 = _degToRad(origin.longitude);

    final lat2 = math.asin(
      (math.sin(lat1) * math.cos(angularDistance)) +
          (math.cos(lat1) * math.sin(angularDistance) * math.cos(bearingRad)),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(bearingRad) * math.sin(angularDistance) * math.cos(lat1),
          math.cos(angularDistance) - (math.sin(lat1) * math.sin(lat2)),
        );

    return ll.LatLng(_radToDeg(lat2), _normalizeLongitude(_radToDeg(lon2)));
  }

  double _degToRad(double value) => value * (math.pi / 180);
  double _radToDeg(double value) => value * (180 / math.pi);
}

class _SimTelemetry {
  const _SimTelemetry({required this.speedKmh, required this.altitudeMeters});

  final double speedKmh;
  final double altitudeMeters;
}
