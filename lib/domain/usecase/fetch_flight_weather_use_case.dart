import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:flymap/domain/policy/flight_overhead_time_policy.dart';
import 'package:flymap/domain/provider/weather_forecast_provider.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/share_flight/utils/static_route_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

/// Fetches the "overhead time" weather picture for a flight: surface
/// forecasts at both airports (at STD/STA) plus ~15-20 cloud samples along
/// the route, each at the moment the plane is over that point.
///
/// A full picture contains 2 airport + 5–20 corridor + up to ~36 area-grid
/// + 8 airport-ring locations (typically ~45–58 points). They are sent in one
/// provider-neutral batch. Caching and upstream transport policy belong to the
/// injected [WeatherForecastProvider].
class FetchFlightWeatherUseCase {
  FetchFlightWeatherUseCase({
    required WeatherForecastProvider provider,
    AirportTimezoneService? timezoneService,
    DateTime Function()? now,
  }) : _provider = provider,
       _timezoneService = timezoneService,
       _now = now ?? DateTime.now;

  /// One sample roughly every this many km along the route.
  static const double sampleSpacingKm = 75;
  static const int minSamples = 5;
  static const int maxSamples = 20;

  /// Grid spacing (in the square map-card viewport) for the full-card
  /// cloud field; grid cells the corridor already covers are skipped.
  static const double areaGridSpacingPx = 95;

  /// Ring of extra samples around each airport (N/E/S/W at this radius).
  /// The airport anchor alone loses the field's normalized nearest-neighbor
  /// vote to corridor/ocean samples hundreds of km away; a ring of real
  /// nearby data turns "lone anchor" into local consensus, so a front
  /// sitting over the airport survives interpolation (the LHR->JFK bug).
  static const double airportRingKm = 50;
  final WeatherForecastProvider _provider;
  final AirportTimezoneService? _timezoneService;
  final DateTime Function() _now;
  final _logger = const Logger('FetchFlightWeatherUseCase');

  Future<FlightWeather> call({
    required FlightRoute route,
    FlightSchedule? schedule,
  }) async {
    if (schedule != null &&
        schedule.timePrecision == FlightScheduleTimePrecision.dateOnly) {
      throw const WeatherDepartureTimeRequiredException();
    }
    // Airport-timezone fallback needs the airports CSV loaded.
    await _timezoneService?.ensureReady();
    final (departureUtc, isTimeEstimated) = _departureUtc(route, schedule);
    // Real STA when the schedule pick provided one; block-time estimate
    // otherwise.
    final scheduledArrivalUtc = schedule?.arrival?.utc;
    final arrivalUtc =
        scheduledArrivalUtc != null && scheduledArrivalUtc.isAfter(departureUtc)
        ? scheduledArrivalUtc
        : departureUtc.add(
            Duration(minutes: math.max(30, route.durations.blockMinutes)),
          );
    final cruiseMinutes = route.durations.cruiseMinutes;
    final points = _samplePoints(route);
    final areaPoints = _areaGridPoints(route, points);

    // Offset precedence: schedule provider (authoritative for the exact
    // flight) -> airport timezone lookup (offline, DST-correct) -> zero /
    // departure offset as the last honest fallback.
    final departureOffset =
        schedule?.departure?.offsetMinutes ??
        _timezoneService?.utcOffsetMinutes(route.departure, departureUtc) ??
        0;
    final arrivalOffset =
        schedule?.arrival?.offsetMinutes ??
        _timezoneService?.utcOffsetMinutes(route.arrival, arrivalUtc) ??
        departureOffset;
    // Timeline window: the whole flight ±1 h, for animating cloud
    // evolution — the provider response contains it anyway.
    final windowStart = departureUtc.subtract(const Duration(hours: 1));
    final windowEnd = arrivalUtc.add(const Duration(hours: 1));
    final requests = <_PointRequest>[
      _PointRequest(route.departure.latLon, departureUtc),
      _PointRequest(route.arrival.latLon, arrivalUtc),
      for (final point in points)
        _PointRequest(
          point.latLon,
          FlightOverheadTimePolicy.estimate(
            departureUtc: departureUtc,
            arrivalUtc: arrivalUtc,
            cruiseMinutes: cruiseMinutes,
            routeProgress: point.routeProgress,
          ),
          routeProgress: point.routeProgress,
        ),
      for (final point in areaPoints)
        _PointRequest(
          point.latLon,
          FlightOverheadTimePolicy.estimate(
            departureUtc: departureUtc,
            arrivalUtc: arrivalUtc,
            cruiseMinutes: cruiseMinutes,
            routeProgress: point.routeProgress,
          ),
          routeProgress: point.routeProgress,
          isAreaSample: true,
        ),
      // Airport rings render with the field (area samples) but never enter
      // the verdict/segment logic, which reads corridor samples only.
      for (final point in _airportRingPoints(route.departure.latLon))
        _PointRequest(
          point,
          departureUtc,
          routeProgress: 0,
          isAreaSample: true,
        ),
      for (final point in _airportRingPoints(route.arrival.latLon))
        _PointRequest(point, arrivalUtc, routeProgress: 1, isAreaSample: true),
    ];
    final batch = await _fetchAll(
      requests,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    final results = batch.results;

    final departureForecast = _atTargetTime(results[0]);
    final arrivalForecast = _atTargetTime(results[1]);
    if (departureForecast == null || arrivalForecast == null) {
      throw const WeatherUnavailableException();
    }

    final samples = <RouteCloudSample>[];
    final areaSamples = <RouteCloudSample>[];

    // Anchor the cloud field AT the two airports using the forecasts already
    // fetched for the cards. Without these the field has no data point at the
    // airport (endpoints are otherwise excluded from the corridor), so the map
    // could look clear over an airport its card shows as cloudy/rainy.
    final departureSample = _buildCloudSample(
      results[0],
      progress: 0,
      timeUtc: departureUtc,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    if (departureSample != null) samples.add(departureSample);
    final arrivalSample = _buildCloudSample(
      results[1],
      progress: 1,
      timeUtc: arrivalUtc,
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    if (arrivalSample != null) samples.add(arrivalSample);

    for (final result in results.skip(2)) {
      final progress = result.request.routeProgress;
      if (progress == null) continue;
      final sample = _buildCloudSample(
        result,
        progress: progress,
        timeUtc: result.request.targetTimeUtc,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      if (sample == null) continue;
      (result.request.isAreaSample ? areaSamples : samples).add(sample);
    }
    // Corridor samples must stay in route order — the verdict/segment logic
    // and the field's centerline both assume ascending progress.
    samples.sort((a, b) => a.routeProgress.compareTo(b.routeProgress));
    _logger.log(
      'weather fetched: samples=${samples.length}/${points.length} '
      'area=${areaSamples.length}/${areaPoints.length} '
      'estimated=$isTimeEstimated',
    );

    return FlightWeather(
      departure: _airportWeather(
        departureForecast,
        departureUtc,
        departureOffset,
      ),
      arrival: _airportWeather(arrivalForecast, arrivalUtc, arrivalOffset),
      samples: samples,
      areaSamples: areaSamples,
      fetchedAt: batch.retrievedAtUtc,
      isTimeEstimated: isTimeEstimated,
      attribution: batch.attribution,
    );
  }

  /// Builds one cloud-field sample from a fetched point: the overhead-time
  /// cloud values plus a within-window timeline for the animation.
  /// Returns null when the point returned no usable forecast.
  RouteCloudSample? _buildCloudSample(
    _PointResult result, {
    required double progress,
    required DateTime timeUtc,
    required DateTime windowStart,
    required DateTime windowEnd,
  }) {
    final forecast = _atTargetTime(result);
    if (forecast == null) return null;
    // Bracket the window with the nearest entry on each side. Beyond ~2.5
    // days out the provider is 6-HOURLY, so the flight window often contains
    // a single entry — the animation would freeze on that one slice and the
    // map could contradict the airport cards, which read the entry nearest
    // to STD/STA (possibly the excluded one). Brackets guarantee >=2 slices
    // so hiddenAt() interpolates through the flight instead of clamping.
    WeatherForecastPoint? before;
    WeatherForecastPoint? after;
    final inWindow = <WeatherForecastPoint>[];
    for (final slice in result.series) {
      if (slice.timeUtc.isBefore(windowStart)) {
        if (before == null || slice.timeUtc.isAfter(before.timeUtc)) {
          before = slice;
        }
      } else if (slice.timeUtc.isAfter(windowEnd)) {
        if (after == null || slice.timeUtc.isBefore(after.timeUtc)) {
          after = slice;
        }
      } else {
        inWindow.add(slice);
      }
    }
    return RouteCloudSample(
      routeProgress: progress,
      latLon: result.request.latLon,
      timeUtc: timeUtc,
      cloudLowPercent: forecast.cloudLowPercent ?? 0,
      cloudMidPercent: forecast.cloudMidPercent ?? 0,
      cloudHighPercent: forecast.cloudHighPercent ?? 0,
      precipitationMm: forecast.precipitationMm,
      timeline: [
        for (final slice in [
          if (before != null) before,
          ...inWindow,
          if (after != null) after,
        ])
          CloudTimeSlice(
            timeUtc: slice.timeUtc,
            cloudLowPercent: slice.cloudLowPercent ?? 0,
            cloudMidPercent: slice.cloudMidPercent ?? 0,
            cloudHighPercent: slice.cloudHighPercent ?? 0,
            precipitationMm: slice.precipitationMm ?? 0,
          ),
      ],
    );
  }

  /// N/E/S/W points [airportRingKm] from [center].
  List<LatLng> _airportRingPoints(LatLng center) {
    const kmPerDegreeLat = 111.0;
    final dLat = airportRingKm / kmPerDegreeLat;
    // Longitude degrees shrink toward the poles; floor the cosine so polar
    // airports don't fling ring points across half the map.
    final cosLat = math.max(
      0.2,
      math.cos(center.latitude * math.pi / 180).abs(),
    );
    final dLon = airportRingKm / (kmPerDegreeLat * cosLat);
    double clampLat(double lat) => math.max(-89.0, math.min(89.0, lat));
    return [
      LatLng(clampLat(center.latitude + dLat), center.longitude),
      LatLng(clampLat(center.latitude - dLat), center.longitude),
      LatLng(center.latitude, _wrapLon(center.longitude + dLon)),
      LatLng(center.latitude, _wrapLon(center.longitude - dLon)),
    ];
  }

  static double _wrapLon(double lon) {
    var next = lon;
    while (next > 180) {
      next -= 360;
    }
    while (next < -180) {
      next += 360;
    }
    return next;
  }

  /// Sparse grid over the map card's viewport (the same square framing the
  /// card renders), skipping cells the corridor samples already cover. Each
  /// grid point borrows the overhead time of the nearest route point so the
  /// full-card field animates coherently with the corridor.
  List<({LatLng latLon, double routeProgress})> _areaGridPoints(
    FlightRoute route,
    List<({LatLng latLon, double routeProgress})> routePoints,
  ) {
    final waypoints = route.waypointLatLngs;
    final framePoints = waypoints.length >= 2
        ? waypoints
        : [route.departure.latLon, route.arrival.latLon];
    final viewport = StaticRouteMap.buildViewport(
      points: framePoints,
      width: staticWeatherMapSize,
      height: staticWeatherMapSize,
    );
    final projectedRoute = StaticRouteMap.projectRoute(
      points: routePoints.map((p) => p.latLon).toList(growable: false),
      viewport: viewport,
    );

    final grid = <({LatLng latLon, double routeProgress})>[];
    for (
      var x = areaGridSpacingPx / 2;
      x < viewport.width;
      x += areaGridSpacingPx
    ) {
      for (
        var y = areaGridSpacingPx / 2;
        y < viewport.height;
        y += areaGridSpacingPx
      ) {
        final pixel = Offset(x, y);
        // Skip cells the corridor band already covers; remember the nearest
        // route point's progress for the overhead time either way.
        var nearestDistance = double.infinity;
        var nearestProgress = 0.5;
        for (var i = 0; i < projectedRoute.length; i++) {
          final distance = (projectedRoute[i].toOffset() - pixel).distance;
          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestProgress = routePoints[i].routeProgress;
          }
        }
        if (nearestDistance < areaGridSpacingPx * 0.7) continue;
        grid.add((
          latLon: StaticRouteMap.unproject(viewport: viewport, point: pixel),
          routeProgress: nearestProgress,
        ));
      }
    }
    return grid;
  }

  /// Provider STD when known; otherwise the user-supplied approximate local
  /// time, flagged as an estimate. Estimated
  /// targets are clamped to 30 minutes from now so choosing Today late in the
  /// day never collapses the entire animation onto past/current forecast data.
  (DateTime, bool) _departureUtc(FlightRoute route, FlightSchedule? schedule) {
    final scheduled = schedule?.departure?.utc;
    if (scheduled != null) return (scheduled, false);
    final travelDate = schedule?.travelDate;
    if (travelDate != null) {
      final approximate = schedule?.approximateDepartureTime;
      if (approximate == null) {
        throw const WeatherDepartureTimeRequiredException();
      }
      final hour = approximate.hour;
      final minute = approximate.minute;
      final airportTime = _timezoneService?.localTimeToUtc(
        route.departure,
        travelDate,
        hour: hour,
        minute: minute,
      );
      final localTime = DateTime(
        travelDate.year,
        travelDate.month,
        travelDate.day,
        hour,
        minute,
      );
      final candidate = airportTime ?? localTime.toUtc();
      final minimum = _now().toUtc().add(const Duration(minutes: 30));
      return (candidate.isBefore(minimum) ? minimum : candidate, true);
    }
    return (_now().toUtc().add(const Duration(hours: 2)), true);
  }

  AirportWeather _airportWeather(
    WeatherForecastPoint forecast,
    DateTime timeUtc,
    int utcOffsetMinutes,
  ) {
    return AirportWeather(
      timeUtc: timeUtc,
      utcOffsetMinutes: utcOffsetMinutes,
      temperatureC: forecast.temperatureC,
      windSpeedMs: forecast.windSpeedMs,
      precipitationMm: forecast.precipitationMm,
      cloudCoverPercent: forecast.cloudCoverPercent,
      symbolCode: forecast.symbolCode,
    );
  }

  /// Evenly spaced points along the route polyline (great-circle line when
  /// no waypoints exist), excluding the endpoints (airports are separate).
  List<({LatLng latLon, double routeProgress})> _samplePoints(
    FlightRoute route,
  ) {
    final polyline = route.waypointLatLngs.length >= 2
        ? route.waypointLatLngs
        : [route.departure.latLon, route.arrival.latLon];
    final distanceKm = math.max(1.0, route.distanceInKm);
    final sampleCount = (distanceKm / sampleSpacingKm).round().clamp(
      minSamples,
      maxSamples,
    );

    // Cumulative distances along the polyline for progress-accurate
    // interpolation.
    final cumulative = <double>[0];
    for (var i = 1; i < polyline.length; i++) {
      cumulative.add(
        cumulative[i - 1] +
            MapUtils.distanceKm(
              departure: polyline[i - 1],
              arrival: polyline[i],
            ),
      );
    }
    final total = cumulative.last <= 0 ? 1.0 : cumulative.last;

    final points = <({LatLng latLon, double routeProgress})>[];
    for (var s = 1; s <= sampleCount; s++) {
      final progress = s / (sampleCount + 1);
      final target = progress * total;
      var segment = 1;
      while (segment < cumulative.length - 1 && cumulative[segment] < target) {
        segment++;
      }
      final segmentStart = cumulative[segment - 1];
      final segmentLength = cumulative[segment] - segmentStart;
      final t = segmentLength <= 0
          ? 0.0
          : ((target - segmentStart) / segmentLength).clamp(0.0, 1.0);
      final a = polyline[segment - 1];
      final b = polyline[segment];
      points.add((
        latLon: MapUtils.interpolateGreatCircle(from: a, to: b, progress: t),
        routeProgress: progress,
      ));
    }
    return points;
  }

  Future<_FlightPointBatch> _fetchAll(
    List<_PointRequest> requests, {
    required DateTime windowStart,
    required DateTime windowEnd,
  }) async {
    try {
      final batch = await _provider.forecastBatch(
        requests: [
          for (final request in requests)
            WeatherForecastRequest(
              coordinate: request.latLon,
              targetTimeUtc: request.targetTimeUtc,
            ),
        ],
        windowStartUtc: windowStart,
        windowEndUtc: windowEnd,
      );
      if (batch.seriesByRequest.length != requests.length) {
        throw const FormatException('Weather batch response count mismatch');
      }
      return _FlightPointBatch(
        results: [
          for (var index = 0; index < requests.length; index++)
            _PointResult(requests[index], batch.seriesByRequest[index]),
        ],
        retrievedAtUtc: batch.retrievedAtUtc,
        attribution: batch.attribution,
      );
    } catch (e) {
      _logger.error('weather batch failed: $e');
      return _FlightPointBatch(
        results: [
          for (final request in requests) _PointResult(request, const []),
        ],
        retrievedAtUtc: _now().toUtc(),
        attribution: WeatherAttribution.metNorway,
      );
    }
  }

  /// Forecast values at this location's expected overflight instant.
  ///
  /// Provider series are normally hourly near-term and may be six-hourly at
  /// longer horizons. Interpolating continuous values avoids snapping a
  /// passenger's view forecast to whichever model step happens to be closer.
  WeatherForecastPoint? _atTargetTime(_PointResult result) {
    final target = result.request.targetTimeUtc;
    WeatherForecastPoint? before;
    WeatherForecastPoint? after;
    WeatherForecastPoint? nearest;
    Duration? nearestDistance;
    for (final point in result.series) {
      final distance = point.timeUtc.difference(target).abs();
      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;
        nearest = point;
      }
      if (!point.timeUtc.isAfter(target) &&
          (before == null || point.timeUtc.isAfter(before.timeUtc))) {
        before = point;
      }
      if (!point.timeUtc.isBefore(target) &&
          (after == null || point.timeUtc.isBefore(after.timeUtc))) {
        after = point;
      }
    }
    if (nearest == null ||
        nearestDistance == null ||
        nearestDistance > const Duration(hours: 12)) {
      return null;
    }
    if (before == null ||
        after == null ||
        before.timeUtc == after.timeUtc ||
        target.difference(before.timeUtc) > const Duration(hours: 12) ||
        after.timeUtc.difference(target) > const Duration(hours: 12)) {
      return nearest;
    }

    final spanMicroseconds = after.timeUtc
        .difference(before.timeUtc)
        .inMicroseconds;
    if (spanMicroseconds <= 0) return nearest;
    final fraction =
        target.difference(before.timeUtc).inMicroseconds / spanMicroseconds;

    double? interpolate(double? first, double? second, double? fallback) {
      if (first != null && second != null) {
        return first + (second - first) * fraction;
      }
      return fallback ?? first ?? second;
    }

    return WeatherForecastPoint(
      timeUtc: target,
      temperatureC: interpolate(
        before.temperatureC,
        after.temperatureC,
        nearest.temperatureC,
      ),
      windSpeedMs: interpolate(
        before.windSpeedMs,
        after.windSpeedMs,
        nearest.windSpeedMs,
      ),
      cloudCoverPercent: interpolate(
        before.cloudCoverPercent,
        after.cloudCoverPercent,
        nearest.cloudCoverPercent,
      ),
      cloudLowPercent: interpolate(
        before.cloudLowPercent,
        after.cloudLowPercent,
        nearest.cloudLowPercent,
      ),
      cloudMidPercent: interpolate(
        before.cloudMidPercent,
        after.cloudMidPercent,
        nearest.cloudMidPercent,
      ),
      cloudHighPercent: interpolate(
        before.cloudHighPercent,
        after.cloudHighPercent,
        nearest.cloudHighPercent,
      ),
      precipitationMm: interpolate(
        before.precipitationMm,
        after.precipitationMm,
        nearest.precipitationMm,
      ),
      symbolCode: nearest.symbolCode,
    );
  }
}

/// Both airport forecasts missing — nothing meaningful to show.
class WeatherUnavailableException implements Exception {
  const WeatherUnavailableException();
}

/// A calendar date without a departure time cannot identify a meaningful
/// forecast instant. Callers must collect a precise local time or stay
/// explicitly dateless.
class WeatherDepartureTimeRequiredException implements Exception {
  const WeatherDepartureTimeRequiredException();
}

class _PointRequest {
  const _PointRequest(
    this.latLon,
    this.targetTimeUtc, {
    this.routeProgress,
    this.isAreaSample = false,
  });

  final LatLng latLon;
  final DateTime targetTimeUtc;
  final double? routeProgress;
  final bool isAreaSample;
}

class _PointResult {
  const _PointResult(this.request, this.series);

  final _PointRequest request;
  final List<WeatherForecastPoint> series;
}

class _FlightPointBatch {
  const _FlightPointBatch({
    required this.results,
    required this.retrievedAtUtc,
    required this.attribution,
  });

  final List<_PointResult> results;
  final DateTime retrievedAtUtc;
  final WeatherAttribution attribution;
}
