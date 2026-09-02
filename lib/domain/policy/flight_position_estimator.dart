import 'dart:math' as math;

import 'package:flymap/domain/entity/flight_map_position.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/utils/speed_unit_utils.dart';
import 'package:latlong2/latlong.dart';

/// Dead-reckons a short-lived map position from recent GPS fixes.
///
/// No route geometry is accepted by this class. A previous or planned flight
/// track must never influence the estimate for the current flight.
class FlightPositionEstimator {
  FlightPositionEstimator({required this.departure, required this.arrival});

  static const maxEstimateAge = Duration(minutes: 10);
  static const highConfidenceAge = Duration(minutes: 2);
  static const _historyWindow = Duration(seconds: 30);
  static const _maxSamples = 8;
  static const _minimumSamples = 3;
  static const _minimumSampleSpan = Duration(seconds: 2);
  static const _maximumHorizontalAccuracyMeters = 100.0;
  static const _maximumSpeedAccuracyMetersPerSecond = 30.0;
  static const _maximumCourseAccuracyDegrees = 45.0;
  static const _minimumAirborneSpeedMetersPerSecond = 160 / 3.6;
  static const _minimumAirportClearanceKm = 5.0;
  static const _maximumCourseDisagreementDegrees = 45.0;
  static const _earthRadiusKm = 6371.0088;

  final LatLng departure;
  final LatLng arrival;
  final List<_TimedFix> _fixes = [];

  void reset() => _fixes.clear();

  void recordFix(GpsData data, {required DateTime receivedAt}) {
    if (!_hasUsablePosition(data)) return;
    final receivedUtc = receivedAt.toUtc();
    final recordedUtc = data.recordedAt?.toUtc();
    final fixAt =
        recordedUtc != null &&
            recordedUtc.isAfter(
              receivedUtc.subtract(const Duration(seconds: 20)),
            ) &&
            recordedUtc.isBefore(receivedUtc.add(const Duration(seconds: 2)))
        ? recordedUtc
        : receivedUtc;

    if (_fixes.isNotEmpty && !fixAt.isAfter(_fixes.last.recordedAt)) {
      return;
    }
    _fixes.add(_TimedFix(data: data, recordedAt: fixAt));
    final cutoff = fixAt.subtract(_historyWindow);
    _fixes.removeWhere((fix) => fix.recordedAt.isBefore(cutoff));
    if (_fixes.length > _maxSamples) {
      _fixes.removeRange(0, _fixes.length - _maxSamples);
    }
  }

  FlightMapPosition? estimate({required DateTime now}) {
    if (_fixes.isEmpty) return null;
    final nowUtc = now.toUtc();
    final last = _fixes.last;
    final rawAge = nowUtc.difference(last.recordedAt);
    final age = rawAge.isNegative ? Duration.zero : rawAge;
    final motion = _resolvedMotion();
    if (motion == null) {
      return _lastKnown(last, age);
    }

    final projectedAge = age > maxEstimateAge ? maxEstimateAge : age;
    final distanceKm =
        motion.speedMetersPerSecond * projectedAge.inMilliseconds / 1000000;
    var projected = _destinationPoint(
      LatLng(last.data.latitude!, last.data.longitude!),
      bearingDegrees: motion.courseDegrees,
      distanceKm: distanceKm,
    );

    // The destination is only a terminal safety guard. It never bends or
    // otherwise steers the estimated path.
    final distanceToArrival = _distanceKm(
      LatLng(last.data.latitude!, last.data.longitude!),
      arrival,
    );
    final arrivalCourse = _bearingDegrees(
      LatLng(last.data.latitude!, last.data.longitude!),
      arrival,
    );
    if (distanceKm >= distanceToArrival &&
        _angularDifference(motion.courseDegrees, arrivalCourse) <= 30) {
      projected = arrival;
    }

    final source = age > maxEstimateAge
        ? FlightMapPositionSource.lastKnown
        : FlightMapPositionSource.estimated;
    final confidence = switch (source) {
      FlightMapPositionSource.estimated when age <= highConfidenceAge =>
        FlightMapPositionConfidence.high,
      FlightMapPositionSource.estimated => FlightMapPositionConfidence.low,
      FlightMapPositionSource.lastKnown => FlightMapPositionConfidence.none,
      FlightMapPositionSource.liveGps => FlightMapPositionConfidence.high,
    };
    return FlightMapPosition(
      data: last.data.copyWith(
        latitude: projected.latitude,
        longitude: projected.longitude,
        course: motion.courseDegrees,
      ),
      source: source,
      confidence: confidence,
      gpsAge: age,
      lastGpsFixAt: last.recordedAt,
    );
  }

  FlightMapPosition _lastKnown(_TimedFix fix, Duration age) {
    return FlightMapPosition(
      data: fix.data,
      source: FlightMapPositionSource.lastKnown,
      confidence: FlightMapPositionConfidence.none,
      gpsAge: age,
      lastGpsFixAt: fix.recordedAt,
    );
  }

  _ResolvedMotion? _resolvedMotion() {
    if (_fixes.length < _minimumSamples) return null;
    final samples = _fixes.sublist(_fixes.length - _minimumSamples);
    final span = samples.last.recordedAt.difference(samples.first.recordedAt);
    if (span < _minimumSampleSpan || span > _historyWindow) return null;

    final speeds = <double>[];
    final courses = <double>[];
    for (final sample in samples) {
      final data = sample.data;
      final accuracy = data.accuracy;
      final speed = SpeedUnitUtils.toMetersPerSecond(data.speed);
      final course = data.course;
      if (accuracy == null ||
          !accuracy.isFinite ||
          accuracy > _maximumHorizontalAccuracyMeters ||
          !speed.isFinite ||
          speed < _minimumAirborneSpeedMetersPerSecond ||
          course == null ||
          !course.isFinite ||
          course < 0 ||
          course >= 360) {
        return null;
      }
      final speedAccuracy = data.speedAccuracy;
      if (speedAccuracy != null &&
          (!speedAccuracy.isFinite ||
              speedAccuracy > _maximumSpeedAccuracyMetersPerSecond)) {
        return null;
      }
      final courseAccuracy = data.courseAccuracy;
      if (courseAccuracy != null &&
          (!courseAccuracy.isFinite ||
              courseAccuracy > _maximumCourseAccuracyDegrees)) {
        return null;
      }
      speeds.add(speed);
      courses.add(course);
    }

    final start = LatLng(
      samples.first.data.latitude!,
      samples.first.data.longitude!,
    );
    final end = LatLng(
      samples.last.data.latitude!,
      samples.last.data.longitude!,
    );
    if (_distanceKm(end, departure) < _minimumAirportClearanceKm ||
        _distanceKm(end, arrival) < _minimumAirportClearanceKm) {
      return null;
    }

    speeds.sort();
    final medianSpeed = speeds[speeds.length ~/ 2];
    final observedSpeed =
        _distanceKm(start, end) *
        1000 /
        (span.inMilliseconds / Duration.millisecondsPerSecond);
    if (!observedSpeed.isFinite ||
        observedSpeed < _minimumAirborneSpeedMetersPerSecond ||
        observedSpeed < medianSpeed * 0.45 ||
        observedSpeed > medianSpeed * 1.65) {
      return null;
    }

    final motionCourse = _bearingDegrees(start, end);
    final smoothedCourse = _weightedCircularMean(courses);
    if (_angularDifference(motionCourse, smoothedCourse) >
        _maximumCourseDisagreementDegrees) {
      return null;
    }
    for (final course in courses) {
      if (_angularDifference(course, smoothedCourse) >
          _maximumCourseDisagreementDegrees) {
        return null;
      }
    }
    return _ResolvedMotion(
      speedMetersPerSecond: medianSpeed,
      courseDegrees: smoothedCourse,
    );
  }

  bool _hasUsablePosition(GpsData data) {
    final lat = data.latitude;
    final lon = data.longitude;
    return lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  double _weightedCircularMean(List<double> courses) {
    var x = 0.0;
    var y = 0.0;
    for (var index = 0; index < courses.length; index++) {
      final weight = (index + 1).toDouble();
      final radians = _degreesToRadians(courses[index]);
      x += math.cos(radians) * weight;
      y += math.sin(radians) * weight;
    }
    return _normalizeDegrees(_radiansToDegrees(math.atan2(y, x)));
  }

  double _distanceKm(LatLng from, LatLng to) {
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final dLat = lat2 - lat1;
    final dLon = _degreesToRadians(
      _normalizeLongitude(to.longitude - from.longitude),
    );
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    final clamped = a.clamp(0.0, 1.0).toDouble();
    return _earthRadiusKm *
        2 *
        math.atan2(math.sqrt(clamped), math.sqrt(1 - clamped));
  }

  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final dLon = _degreesToRadians(
      _normalizeLongitude(to.longitude - from.longitude),
    );
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return _normalizeDegrees(_radiansToDegrees(math.atan2(y, x)));
  }

  LatLng _destinationPoint(
    LatLng start, {
    required double bearingDegrees,
    required double distanceKm,
  }) {
    final angularDistance = distanceKm / _earthRadiusKm;
    final bearing = _degreesToRadians(bearingDegrees);
    final lat1 = _degreesToRadians(start.latitude);
    final lon1 = _degreesToRadians(start.longitude);
    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angularDistance) +
          math.cos(lat1) * math.sin(angularDistance) * math.cos(bearing),
    );
    final lon2 =
        lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(lat1),
          math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
        );
    return LatLng(
      _radiansToDegrees(lat2),
      _normalizeLongitude(_radiansToDegrees(lon2)),
    );
  }

  double _angularDifference(double a, double b) {
    final delta = (_normalizeDegrees(a) - _normalizeDegrees(b)).abs();
    return delta > 180 ? 360 - delta : delta;
  }

  double _normalizeDegrees(double value) {
    final normalized = value % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _normalizeLongitude(double value) {
    var normalized = value;
    while (normalized > 180) {
      normalized -= 360;
    }
    while (normalized < -180) {
      normalized += 360;
    }
    return normalized;
  }

  double _degreesToRadians(double value) => value * math.pi / 180;
  double _radiansToDegrees(double value) => value * 180 / math.pi;
}

class _TimedFix {
  const _TimedFix({required this.data, required this.recordedAt});

  final GpsData data;
  final DateTime recordedAt;
}

class _ResolvedMotion {
  const _ResolvedMotion({
    required this.speedMetersPerSecond,
    required this.courseDegrees,
  });

  final double speedMetersPerSecond;
  final double courseDegrees;
}
