import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/logger.dart';

/// Calls `search_upcoming_flights_by_number`: the 7-day scheduled-departure
/// window for a flight number (AeroDataBox), each entry stitched to the most
/// recent recorded FR24 leg so the preview pipeline works unchanged.
class UpcomingFlightSearchApi {
  UpcomingFlightSearchApi({
    FirebaseFunctions? functions,
    Future<dynamic> Function(String function, Map<String, dynamic> payload)?
    invokeCallable,
  }) : _functions = functions,
       _invokeCallable = invokeCallable;

  static const _function = 'search_upcoming_flights_by_number';

  final FirebaseFunctions? _functions;
  final Future<dynamic> Function(String function, Map<String, dynamic> payload)?
  _invokeCallable;
  final _logger = const Logger('UpcomingFlightSearchApi');

  Future<List<Map<String, dynamic>>> searchUpcomingFlightsByNumber(
    String flightNumber,
  ) async {
    final normalizedFlightNumber = _normalizeFlightNumber(flightNumber);
    if (normalizedFlightNumber == null) {
      throw ArgumentError('flightNumber must be non-empty');
    }

    _logger.log('callable=$_function flightNumber=$normalizedFlightNumber');
    try {
      final decoded = _decodeFunctionData(
        await _callFunction(normalizedFlightNumber: normalizedFlightNumber),
      );
      if (decoded is! Map) {
        throw const FormatException(
          'search_upcoming_flights_by_number returned non-object payload',
        );
      }

      final payload = decoded.cast<String, dynamic>();
      final flights = payload['flights'];
      if (flights is! List) {
        throw const FormatException(
          'search_upcoming_flights_by_number payload missing flights list',
        );
      }

      final parsedFlights = flights
          .map<Map<String, dynamic>>((dynamic item) {
            if (item is! Map) {
              throw const FormatException(
                'search_upcoming_flights_by_number flights item was not an object',
              );
            }
            return item.cast<String, dynamic>();
          })
          .toList(growable: false);

      _logger.log(
        'parsed count=${parsedFlights.length} flightNumber=$normalizedFlightNumber',
      );
      return parsedFlights;
    } catch (e) {
      _logger.error(
        'failed callable=$_function flightNumber=$normalizedFlightNumber error=$e',
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

  Future<dynamic> _callFunction({
    required String normalizedFlightNumber,
  }) async {
    final payload = <String, dynamic>{'flightNumber': normalizedFlightNumber};
    final invokeCallable = _invokeCallable;
    if (invokeCallable != null) {
      return invokeCallable(_function, payload);
    }
    final functions = _functions ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable(_function).call(payload);
    return result.data;
  }
}
