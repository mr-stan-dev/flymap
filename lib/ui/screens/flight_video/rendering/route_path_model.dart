import 'dart:math';

import 'package:flymap/domain/entity/flight_route.dart';
import 'package:latlong2/latlong.dart';

/// Arc-length parameterized flight path used by the flight-video renderer.
///
/// Longitudes are unwrapped (they may leave [-180, 180]) so antimeridian
/// routes stay continuous; only tile fetching re-wraps coordinates.
class RoutePathModel {
  RoutePathModel._({
    required List<LatLng> samples,
    required this.totalKm,
  }) : _samples = samples;

  factory RoutePathModel.fromRoute(FlightRoute route, {int samples = 512}) {
    var raw = route.waypointLatLngs;
    if (raw.length < 2) {
      raw = [route.departure.latLon, route.arrival.latLon];
    }
    return RoutePathModel.fromPoints(raw, samples: samples);
  }

  factory RoutePathModel.fromPoints(List<LatLng> raw, {int samples = 512}) {
    assert(raw.length >= 2, 'A route needs at least two points');
    final unwrapped = _unwrap(_dedupe(raw));
    // Sparse routes (e.g. plain departure->arrival) are densified along the
    // great circle so the plane flies a realistic curve, not a mercator line.
    final densified = unwrapped.length < 32
        ? _unwrap(_densifyGreatCircle(unwrapped, segments: 128))
        : unwrapped;
    // Resample first so the smoothing window is uniform in ground distance,
    // smooth away the sharp jinks real FR24 tracks have (approach turns,
    // holding patterns), then resample again to restore even spacing.
    final even = _resample(densified, samples);
    final smoothed = _smoothAdaptive(even._samples);
    return _resample(smoothed, samples);
  }

  final List<LatLng> _samples;

  /// Total path length in kilometers.
  final double totalKm;

  /// Evenly spaced (by ground distance) path points with unwrapped longitude.
  List<LatLng> get samplePoints => _samples;

  LatLng get departure => _samples.first;

  LatLng get arrival => _samples.last;

  /// Latitude at the middle of the path (for zoom/latitude compensation).
  double get midLat => pointAt(0.5).latitude;

  /// Point at normalized arc length [s] in 0..1.
  LatLng pointAt(double s) {
    final clamped = s.clamp(0.0, 1.0);
    final position = clamped * (_samples.length - 1);
    final index = position.floor();
    if (index >= _samples.length - 1) return _samples.last;
    final f = position - index;
    final a = _samples[index];
    final b = _samples[index + 1];
    // Samples are close together, so linear interpolation is accurate enough.
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * f,
      a.longitude + (b.longitude - a.longitude) * f,
    );
  }

  /// Course over ground at normalized arc length [s], degrees from north.
  double bearingDegAt(double s) {
    const ds = 0.002;
    final from = pointAt((s - ds).clamp(0.0, 1.0 - ds));
    final to = pointAt((s + ds).clamp(ds, 1.0));
    return bearingBetween(from, to);
  }

  static double bearingBetween(LatLng from, LatLng to) {
    final phi1 = _rad(from.latitude);
    final phi2 = _rad(to.latitude);
    final dLambda = _rad(to.longitude - from.longitude);
    final y = sin(dLambda) * cos(phi2);
    final x = cos(phi1) * sin(phi2) - sin(phi1) * cos(phi2) * cos(dLambda);
    if (x == 0 && y == 0) return 0;
    return _deg(atan2(y, x));
  }

  static double haversineKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dPhi = _rad(b.latitude - a.latitude);
    final dLambda = _rad(b.longitude - a.longitude);
    final h =
        pow(sin(dPhi / 2), 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * pow(sin(dLambda / 2), 2);
    return 2 * earthRadiusKm * asin(min(1.0, sqrt(h.toDouble())));
  }

  static RoutePathModel _resample(List<LatLng> points, int samples) {
    final cumulative = List<double>.filled(points.length, 0);
    for (var i = 1; i < points.length; i++) {
      cumulative[i] = cumulative[i - 1] + haversineKm(points[i - 1], points[i]);
    }
    final totalKm = max(cumulative.last, 1e-6);

    final count = max(16, samples);
    final resampled = List<LatLng>.filled(count, points.first);
    var cursor = 0;
    for (var i = 0; i < count; i++) {
      final target = totalKm * i / (count - 1);
      while (cursor < points.length - 2 && cumulative[cursor + 1] < target) {
        cursor++;
      }
      final segment = max(1e-12, cumulative[cursor + 1] - cumulative[cursor]);
      final f = ((target - cumulative[cursor]) / segment).clamp(0.0, 1.0);
      final a = points[cursor];
      final b = points[cursor + 1];
      resampled[i] = LatLng(
        a.latitude + (b.latitude - a.latitude) * f,
        a.longitude + (b.longitude - a.longitude) * f,
      );
    }
    return RoutePathModel._(samples: resampled, totalKm: totalKm);
  }

  /// Two box-smoothing passes whose window shrinks to zero at the endpoints:
  /// airports stay pinned exactly while sharp turns near them (and anywhere
  /// along the track) melt into gentle curves the camera can follow.
  static List<LatLng> _smoothAdaptive(
    List<LatLng> points, {
    double baseWindowFraction = 0.025,
    int passes = 2,
  }) {
    final n = points.length;
    if (n < 5) return points;
    final base = max(2, (n * baseWindowFraction).round());

    var current = points;
    for (var pass = 0; pass < passes; pass++) {
      final out = List<LatLng>.filled(n, current.first);
      for (var i = 0; i < n; i++) {
        final w = min(base, min(i, n - 1 - i));
        if (w == 0) {
          out[i] = current[i];
          continue;
        }
        var lat = 0.0;
        var lon = 0.0;
        for (var j = i - w; j <= i + w; j++) {
          lat += current[j].latitude;
          lon += current[j].longitude;
        }
        final count = 2 * w + 1;
        out[i] = LatLng(lat / count, lon / count);
      }
      current = out;
    }
    return current;
  }

  static List<LatLng> _dedupe(List<LatLng> points) {
    final result = <LatLng>[points.first];
    for (final p in points.skip(1)) {
      final last = result.last;
      if ((p.latitude - last.latitude).abs() > 1e-9 ||
          (p.longitude - last.longitude).abs() > 1e-9) {
        result.add(p);
      }
    }
    if (result.length < 2) {
      // Degenerate route (departure == arrival): nudge so math stays finite.
      final p = result.first;
      result.add(LatLng(p.latitude, p.longitude + 0.01));
    }
    return result;
  }

  /// Same unwrap convention as `StaticRouteMap._unwrapRoute`.
  static List<LatLng> _unwrap(List<LatLng> points) {
    if (points.length <= 1) return points;
    final unwrapped = <LatLng>[points.first];
    var prevLon = points.first.longitude;
    for (var i = 1; i < points.length; i++) {
      var lon = points[i].longitude;
      while (lon - prevLon > 180) {
        lon -= 360;
      }
      while (lon - prevLon < -180) {
        lon += 360;
      }
      unwrapped.add(LatLng(points[i].latitude, lon));
      prevLon = lon;
    }
    return unwrapped;
  }

  static List<LatLng> _densifyGreatCircle(
    List<LatLng> points, {
    required int segments,
  }) {
    var totalKm = 0.0;
    for (var i = 1; i < points.length; i++) {
      totalKm += haversineKm(points[i - 1], points[i]);
    }
    if (totalKm <= 0) return points;

    final result = <LatLng>[points.first];
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1];
      final b = points[i];
      final legKm = haversineKm(a, b);
      final steps = max(1, (segments * legKm / totalKm).ceil());
      for (var s = 1; s <= steps; s++) {
        result.add(_slerp(a, b, s / steps));
      }
    }
    return result;
  }

  /// Spherical interpolation between two points (great-circle midpoints).
  static LatLng _slerp(LatLng a, LatLng b, double f) {
    final v1 = _toVector(a);
    final v2 = _toVector(b);
    final dot = (v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]).clamp(
      -1.0,
      1.0,
    );
    final omega = acos(dot);
    if (omega < 1e-9) return f < 0.5 ? a : b;
    final sinOmega = sin(omega);
    final c1 = sin((1 - f) * omega) / sinOmega;
    final c2 = sin(f * omega) / sinOmega;
    final x = c1 * v1[0] + c2 * v2[0];
    final y = c1 * v1[1] + c2 * v2[1];
    final z = c1 * v1[2] + c2 * v2[2];
    final lat = _deg(atan2(z, sqrt(x * x + y * y)));
    final lon = _deg(atan2(y, x));
    return LatLng(lat, lon);
  }

  static List<double> _toVector(LatLng p) {
    final phi = _rad(p.latitude);
    final lambda = _rad(p.longitude);
    return [cos(phi) * cos(lambda), cos(phi) * sin(lambda), sin(phi)];
  }

  static double _rad(double deg) => deg * pi / 180;

  static double _deg(double rad) => rad * 180 / pi;
}
