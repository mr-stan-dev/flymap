import 'dart:convert';

import 'package:flymap/logger.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// One parsed forecast entry for a coordinate at (approximately) a
/// requested instant.
class MetNorwayForecastPoint {
  const MetNorwayForecastPoint({
    required this.timeUtc,
    this.temperatureC,
    this.windSpeedMs,
    this.cloudCoverPercent,
    this.cloudLowPercent,
    this.cloudMidPercent,
    this.cloudHighPercent,
    this.precipitationMm,
    this.symbolCode,
  });

  final DateTime timeUtc;
  final double? temperatureC;
  final double? windSpeedMs;
  final double? cloudCoverPercent;
  final double? cloudLowPercent;
  final double? cloudMidPercent;
  final double? cloudHighPercent;
  final double? precipitationMm;
  final String? symbolCode;
}

/// MET Norway Locationforecast 2.0 (api.met.no) — keyless and free including
/// commercial use; the terms require an identifying User-Agent with contact
/// info and in-app attribution ("Weather data: MET Norway").
///
/// v1 calls it directly from the app (no backend proxy) — decision
/// 2026-07-28; the client stays isolated so a proxy/provider swap later
/// touches only this file.
class MetNorwayApi {
  MetNorwayApi({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const _host = 'api.met.no';

  // "complete" (not "compact"): only the complete format carries the
  // three-band cloud_area_fraction_low/_medium/_high the verdict needs
  // (verified live 2026-07-28).
  static const _path = '/weatherapi/locationforecast/2.0/complete';
  static const _userAgent =
      'Flymap-app flymap.app (contact: team@apptractor.dev)';

  final http.Client _httpClient;
  final _logger = const Logger('MetNorwayApi');

  /// Fetches the full parsed forecast timeseries for one coordinate
  /// (hourly near-term, 6-hourly beyond, ~9-10 day horizon). One request
  /// returns everything — callers slice out what they need.
  Future<List<MetNorwayForecastPoint>> forecastSeries(LatLng latLon) async {
    final uri = Uri.https(_host, _path, <String, String>{
      // Terms ask for <=4 decimals to improve upstream cache hits.
      'lat': latLon.latitude.toStringAsFixed(4),
      'lon': latLon.longitude.toStringAsFixed(4),
    });
    // A flight fans out ~30 of these; without a timeout one stalled request
    // (connected-but-not-responding Wi-Fi) hangs the whole weather step. The
    // use case treats a throw as "point unavailable" and carries on.
    final response = await _httpClient
        .get(uri, headers: const {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 && response.statusCode != 203) {
      _logger.error('met.no ${response.statusCode} for $uri');
      throw http.ClientException(
        'met.no returned ${response.statusCode}',
        uri,
      );
    }

    final decoded = jsonDecode(response.body);
    final timeseries =
        ((decoded as Map<String, dynamic>)['properties']
                as Map<String, dynamic>?)?['timeseries']
            as List<dynamic>?;
    if (timeseries == null) return const [];

    final points = <MetNorwayForecastPoint>[];
    for (final raw in timeseries) {
      if (raw is! Map) continue;
      final parsed = _parseEntry(raw.cast<String, dynamic>());
      if (parsed != null) points.add(parsed);
    }
    return points;
  }

  /// The series entry closest to [targetTimeUtc], or null when the horizon
  /// does not cover it (closest entry more than 12 h away = stale, not data).
  static MetNorwayForecastPoint? nearestTo(
    List<MetNorwayForecastPoint> series,
    DateTime targetTimeUtc,
  ) {
    MetNorwayForecastPoint? best;
    Duration? bestDistance;
    for (final point in series) {
      final distance = point.timeUtc.difference(targetTimeUtc).abs();
      if (bestDistance == null || distance < bestDistance) {
        bestDistance = distance;
        best = point;
      }
    }
    if (best == null || bestDistance == null || bestDistance.inHours > 12) {
      return null;
    }
    return best;
  }

  MetNorwayForecastPoint? _parseEntry(Map<String, dynamic> entry) {
    final time = DateTime.tryParse((entry['time'] ?? '').toString());
    if (time == null) return null;
    final data = entry['data'];
    if (data is! Map) return null;
    final instant = data['instant'];
    final details = instant is Map ? instant['details'] : null;
    final detailsMap = details is Map
        ? details.cast<String, dynamic>()
        : const <String, dynamic>{};
    // Prefer 1h precipitation/symbol; fall back to the 6h block that
    // longer-horizon entries carry instead.
    final next1h = data['next_1_hours'];
    final next6h = data['next_6_hours'];
    final next = next1h is Map ? next1h : (next6h is Map ? next6h : null);
    // Beyond ~2-3 days MET only has 6-hourly steps, so precipitation_amount is
    // a 6-HOUR TOTAL. Normalize it to an approximate mm/h so it reads as an
    // intensity (comparable to the 1h value) instead of a scary accumulation
    // shown as if it were instantaneous rain right now.
    final isSixHourBlock = next1h is! Map && next6h is Map;
    final nextDetails = next is Map ? next['details'] : null;
    final nextSummary = next is Map ? next['summary'] : null;

    double? toDouble(dynamic raw) => raw is num ? raw.toDouble() : null;

    final rawPrecip = nextDetails is Map
        ? toDouble(nextDetails['precipitation_amount'])
        : null;

    return MetNorwayForecastPoint(
      timeUtc: time.toUtc(),
      temperatureC: toDouble(detailsMap['air_temperature']),
      windSpeedMs: toDouble(detailsMap['wind_speed']),
      cloudCoverPercent: toDouble(detailsMap['cloud_area_fraction']),
      cloudLowPercent: toDouble(detailsMap['cloud_area_fraction_low']),
      cloudMidPercent: toDouble(detailsMap['cloud_area_fraction_medium']),
      cloudHighPercent: toDouble(detailsMap['cloud_area_fraction_high']),
      precipitationMm: isSixHourBlock && rawPrecip != null
          ? rawPrecip / 6
          : rawPrecip,
      symbolCode: nextSummary is Map
          ? (nextSummary['symbol_code'] as String?)
          : null,
    );
  }
}
