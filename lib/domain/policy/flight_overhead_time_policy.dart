import 'dart:math' as math;

/// Estimates when the aircraft reaches a point along the airborne route.
///
/// Scheduled departure and arrival are gate times. Applying route progress to
/// the whole block duration makes the aircraft appear to move along the route
/// while it is still taxiing. Flymap does not know the actual take-off and
/// landing instants, so this policy removes a conservative 25-minute ground
/// allowance when the route's cruise estimate shows that the block contains
/// enough non-cruise time.
class FlightOverheadTimePolicy {
  const FlightOverheadTimePolicy._();

  static const int _typicalTaxiOutMinutes = 15;
  static const int _typicalTaxiInMinutes = 10;
  static const int _typicalGroundMinutes =
      _typicalTaxiOutMinutes + _typicalTaxiInMinutes;

  static DateTime estimate({
    required DateTime departureUtc,
    required DateTime arrivalUtc,
    required int cruiseMinutes,
    required double routeProgress,
  }) {
    final progress = routeProgress.clamp(0.0, 1.0);
    final block = arrivalUtc.difference(departureUtc);
    if (block <= Duration.zero) return departureUtc;

    final blockMinutes = block.inSeconds / Duration.secondsPerMinute;
    if (cruiseMinutes <= 0 || cruiseMinutes >= blockMinutes) {
      return _interpolate(departureUtc, arrivalUtc, progress);
    }

    final nonCruiseMinutes = math.max(0.0, blockMinutes - cruiseMinutes);
    final groundMinutes = math.min(
      _typicalGroundMinutes.toDouble(),
      nonCruiseMinutes,
    );
    if (groundMinutes <= 0) {
      return _interpolate(departureUtc, arrivalUtc, progress);
    }

    final taxiOutMinutes =
        groundMinutes * _typicalTaxiOutMinutes / _typicalGroundMinutes;
    final taxiInMinutes = groundMinutes - taxiOutMinutes;
    final airborneStart = departureUtc.add(
      Duration(seconds: (taxiOutMinutes * Duration.secondsPerMinute).round()),
    );
    final airborneEnd = arrivalUtc.subtract(
      Duration(seconds: (taxiInMinutes * Duration.secondsPerMinute).round()),
    );
    if (!airborneEnd.isAfter(airborneStart)) {
      return _interpolate(departureUtc, arrivalUtc, progress);
    }
    return _interpolate(airborneStart, airborneEnd, progress);
  }

  static DateTime _interpolate(DateTime start, DateTime end, double progress) {
    final spanMicroseconds = end.difference(start).inMicroseconds;
    return start.add(
      Duration(microseconds: (spanMicroseconds * progress).round()),
    );
  }
}
