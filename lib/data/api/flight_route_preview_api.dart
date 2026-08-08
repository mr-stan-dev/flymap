import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/logger.dart';

class FlightRoutePreviewApi {
  FlightRoutePreviewApi({
    FirebaseFunctions? functions,
    Future<dynamic> Function(String function, Map<String, dynamic> payload)?
    invokeCallable,
  }) : _functions = functions,
       _invokeCallable = invokeCallable;

  static const _function = 'build_flight_route_preview';

  final FirebaseFunctions? _functions;
  final Future<dynamic> Function(String function, Map<String, dynamic> payload)?
  _invokeCallable;
  final _logger = const Logger('FlightRoutePreviewApi');

  Future<Map<String, dynamic>> buildFlightRoutePreview({
    required String flightNumber,
    String? fr24Id,
    String? origCode,
    String? destCode,
    required int placesLimit,
    required int regionsLimit,
    String lang = 'en',
  }) async {
    final normalizedFlightNumber = _normalizeFlightNumber(flightNumber);
    final normalizedFr24Id = _normalizeFr24Id(fr24Id);
    final normalizedOrigCode = _normalizeAirportCode(origCode);
    final normalizedDestCode = _normalizeAirportCode(destCode);
    if (normalizedFlightNumber == null) {
      throw ArgumentError('flightNumber must be non-empty');
    }
    _logger.log(
      'callable=$_function flightNumber=$normalizedFlightNumber fr24Id=${normalizedFr24Id ?? "-"} origCode=${normalizedOrigCode ?? "-"} destCode=${normalizedDestCode ?? "-"} placesLimit=$placesLimit regionsLimit=$regionsLimit lang=$lang',
    );
    try {
      final requestPayload = <String, dynamic>{
        'flightNumber': normalizedFlightNumber,
        'placesLimit': placesLimit,
        'regionsLimit': regionsLimit,
        'lang': lang,
      };
      if (normalizedFr24Id != null) {
        requestPayload['fr24Id'] = normalizedFr24Id;
        // The ID came from the selected backend search result, so a compatible
        // backend can fetch its track directly. Older backends ignore this.
        requestPayload['skipSummaryLookup'] = true;
      }
      if (normalizedOrigCode != null) {
        requestPayload['origCode'] = normalizedOrigCode;
      }
      if (normalizedDestCode != null) {
        requestPayload['destCode'] = normalizedDestCode;
      }
      final invokeCallable = _invokeCallable;
      final dynamic rawData;
      if (invokeCallable != null) {
        rawData = await invokeCallable(_function, requestPayload);
      } else {
        final functions = _functions ?? FirebaseFunctions.instance;
        rawData =
            (await functions.httpsCallable(_function).call(requestPayload))
                .data;
      }
      final decoded = _decodeFunctionData(rawData);
      if (decoded is! Map) {
        throw const FormatException(
          'build_flight_route_preview returned non-object payload',
        );
      }
      final payload = decoded.cast<String, dynamic>();
      final route = payload['route'];
      final pathCoordinates =
          route is Map &&
              route['path'] is Map &&
              (route['path'] as Map)['coordinates'] is List
          ? ((route['path'] as Map)['coordinates'] as List).length
          : -1;
      final corridorPolygonCount =
          route is Map &&
              route['corridorMultiPolygon'] is Map &&
              (route['corridorMultiPolygon'] as Map)['coordinates'] is List
          ? ((route['corridorMultiPolygon'] as Map)['coordinates'] as List)
                .length
          : -1;
      final legacyCorridorPoints =
          route is Map &&
              route['corridor'] is Map &&
              (route['corridor'] as Map)['coordinates'] is List &&
              ((route['corridor'] as Map)['coordinates'] as List).isNotEmpty &&
              ((route['corridor'] as Map)['coordinates'] as List).first is List
          ? (((route['corridor'] as Map)['coordinates'] as List).first as List)
                .length
          : -1;
      final placesCount =
          payload['places'] is Map &&
              (payload['places'] as Map)['features'] is List
          ? ((payload['places'] as Map)['features'] as List).length
          : -1;
      final regionsCount = payload['regions'] is List
          ? (payload['regions'] as List).length
          : -1;
      _logger.log(
        'parsed waypoints=$pathCoordinates corridorPolygons=$corridorPolygonCount legacyCorridorPoints=$legacyCorridorPoints places=$placesCount regions=$regionsCount flightNumber=$normalizedFlightNumber',
      );
      return payload;
    } catch (e) {
      _logger.error(
        'failed callable=$_function flightNumber=$normalizedFlightNumber fr24Id=${normalizedFr24Id ?? "-"} error=$e',
      );
      rethrow;
    }
  }

  dynamic _decodeFunctionData(dynamic rawData) {
    if (rawData is String) {
      try {
        return jsonDecode(rawData);
      } catch (_) {
        return rawData;
      }
    }
    return rawData;
  }

  String? _normalizeFlightNumber(String? raw) {
    if (raw == null) return null;
    final value = raw.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  String? _normalizeFr24Id(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  String? _normalizeAirportCode(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toUpperCase();
    return value.isEmpty ? null : value;
  }
}
