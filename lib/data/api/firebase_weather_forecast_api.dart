import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/domain/entity/weather_attribution.dart';
import 'package:flymap/domain/provider/weather_forecast_provider.dart';
import 'package:flymap/logger.dart';

typedef WeatherForecastCallable =
    Future<Object?> Function(Map<String, dynamic> payload);

/// Flymap's provider-neutral, one-call weather transport.
///
/// Upstream provider details stay behind the Firebase function; this adapter
/// only knows the versioned Flymap request and response schema.
class FirebaseWeatherForecastApi implements WeatherForecastProvider {
  FirebaseWeatherForecastApi({
    FirebaseFunctions? functions,
    WeatherForecastCallable? callable,
  }) : _functions = functions,
       _callable = callable;

  static const _function = 'get_flight_weather_forecast';
  static const _contractVersion = 1;
  static const _requestTimeout = Duration(seconds: 60);

  final FirebaseFunctions? _functions;
  final WeatherForecastCallable? _callable;
  final _logger = const Logger('FirebaseWeatherForecastApi');

  @override
  Future<WeatherForecastBatch> forecastBatch({
    required List<WeatherForecastRequest> requests,
    required DateTime windowStartUtc,
    required DateTime windowEndUtc,
  }) async {
    if (requests.isEmpty) {
      return WeatherForecastBatch(
        seriesByRequest: const [],
        retrievedAtUtc: DateTime.now().toUtc(),
        attribution: WeatherAttribution.metNorway,
      );
    }
    final payload = <String, dynamic>{
      'contractVersion': _contractVersion,
      'window': {
        'startUtc': windowStartUtc.toUtc().toIso8601String(),
        'endUtc': windowEndUtc.toUtc().toIso8601String(),
      },
      'locations': [
        for (var index = 0; index < requests.length; index++)
          {
            'id': '$index',
            'latitude': requests[index].coordinate.latitude,
            'longitude': requests[index].coordinate.longitude,
            'targetTimeUtc': requests[index].targetTimeUtc
                .toUtc()
                .toIso8601String(),
          },
      ],
    };
    _logger.log('calling $_function locations=${requests.length}');

    try {
      final raw = await (_callable?.call(payload) ?? _call(payload)).timeout(
        _requestTimeout,
      );
      final batch = _parseBatch(raw, requests.length);
      _logger.log(
        'parsed $_function locations=${requests.length} '
        'available=${batch.seriesByRequest.where((e) => e.isNotEmpty).length}',
      );
      return batch;
    } on FirebaseFunctionsException catch (error) {
      _logger.error(
        'failed $_function code=${error.code} message=${error.message}',
      );
      rethrow;
    } catch (error) {
      _logger.error('failed $_function error=$error');
      rethrow;
    }
  }

  Future<Object?> _call(Map<String, dynamic> payload) async {
    final functions = _functions ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable(_function).call(payload);
    return result.data;
  }

  WeatherForecastBatch _parseBatch(Object? raw, int requestCount) {
    final decoded = raw is String ? jsonDecode(raw) : raw;
    if (decoded is! Map) {
      throw const FormatException('Weather function returned a non-object');
    }
    final map = Map<String, dynamic>.from(decoded);
    if ((map['contractVersion'] as num?)?.toInt() != _contractVersion) {
      throw const FormatException('Unsupported weather contract version');
    }
    final rawLocations = map['locations'];
    if (rawLocations is! List) {
      throw const FormatException('Weather response has no locations');
    }
    final byId = <String, Map<String, dynamic>>{};
    for (final rawLocation in rawLocations) {
      if (rawLocation is! Map) continue;
      final location = Map<String, dynamic>.from(rawLocation);
      final id = location['id'];
      if (id is String) byId[id] = location;
    }

    final timestamps = <DateTime>[];
    final seriesByRequest = <List<WeatherForecastPoint>>[];
    for (var index = 0; index < requestCount; index++) {
      final location = byId['$index'];
      if (location == null || location['status'] != 'ok') {
        seriesByRequest.add(const []);
        continue;
      }
      final timestamp = _date(
        location['sourceUpdatedAtUtc'] ?? location['retrievedAtUtc'],
      );
      if (timestamp != null) timestamps.add(timestamp);
      final rawPoints = location['points'];
      if (rawPoints is! List) {
        seriesByRequest.add(const []);
        continue;
      }
      final parsedPoints = <WeatherForecastPoint>[];
      for (final rawPoint in rawPoints) {
        if (rawPoint is! Map) continue;
        final point = _point(Map<String, dynamic>.from(rawPoint));
        if (point != null) parsedPoints.add(point);
      }
      seriesByRequest.add(parsedPoints);
    }
    if (seriesByRequest.length != requestCount) {
      throw const FormatException('Weather response count mismatch');
    }
    final generatedAt = _date(map['generatedAtUtc']) ?? DateTime.now().toUtc();
    final retrievedAt = timestamps.fold<DateTime>(
      generatedAt,
      (oldest, time) => time.isBefore(oldest) ? time : oldest,
    );
    return WeatherForecastBatch(
      seriesByRequest: seriesByRequest,
      retrievedAtUtc: retrievedAt,
      attribution: _attribution(map['attribution']),
    );
  }

  WeatherForecastPoint? _point(Map<String, dynamic> map) {
    final time = _date(map['timeUtc']);
    if (time == null) return null;
    return WeatherForecastPoint(
      timeUtc: time,
      temperatureC: _number(map['temperatureC']),
      windSpeedMs: _number(map['windSpeedMs']),
      cloudCoverPercent: _number(map['cloudCoverPercent']),
      cloudLowPercent: _number(map['cloudLowPercent']),
      cloudMidPercent: _number(map['cloudMidPercent']),
      cloudHighPercent: _number(map['cloudHighPercent']),
      precipitationMm: _number(map['precipitationMm']),
      symbolCode: map['conditionCode'] as String?,
    );
  }

  WeatherAttribution _attribution(Object? raw) {
    if (raw is! Map) return WeatherAttribution.metNorway;
    final map = Map<String, dynamic>.from(raw);
    final providerName = map['providerName'];
    final providerUrl = map['providerUrl'];
    final licenseName = map['licenseName'];
    final licenseUrl = map['licenseUrl'];
    if (providerName is! String ||
        providerUrl is! String ||
        licenseName is! String ||
        licenseUrl is! String) {
      return WeatherAttribution.metNorway;
    }
    return WeatherAttribution(
      providerName: providerName,
      providerUrl: providerUrl,
      licenseName: licenseName,
      licenseUrl: licenseUrl,
    );
  }

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  double? _number(Object? value) => value is num ? value.toDouble() : null;
}
