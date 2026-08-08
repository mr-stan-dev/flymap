import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flymap/logger.dart';

/// Calls `search_upcoming_flights_by_number`: the 7-day scheduled-departure
/// window for a flight number (AeroDataBox). This app opts out of redundant
/// historical FR24 enrichment; older backends safely retain their old behavior.
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

  /// [date] switches from the default 7-day window to exact-date
  /// verification for that local calendar day.
  Future<List<Map<String, dynamic>>> searchUpcomingFlightsByNumber(
    String flightNumber, {
    DateTime? date,
  }) async {
    final normalizedFlightNumber = _normalizeFlightNumber(flightNumber);
    if (normalizedFlightNumber == null) {
      throw ArgumentError('flightNumber must be non-empty');
    }

    _logger.log(
      'callable=$_function flightNumber=$normalizedFlightNumber'
      '${date == null ? '' : ' date=${_formatDate(date)}'}',
    );
    try {
      final decoded = _decodeFunctionData(
        await _callFunction(
          normalizedFlightNumber: normalizedFlightNumber,
          date: date,
        ),
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

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-$mm-$dd';
  }

  String? _normalizeFlightNumber(String? raw) {
    if (raw == null) return null;
    final value = raw.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
    return value.isEmpty ? null : value;
  }

  Future<dynamic> _callFunction({
    required String normalizedFlightNumber,
    DateTime? date,
  }) async {
    final payload = <String, dynamic>{
      'flightNumber': normalizedFlightNumber,
      // Historical identity is either already retained from the selected
      // candidate or was unavailable in the preceding lookup. Older backends
      // ignore this field; newer ones avoid repeating the summary query.
      'includeHistorical': false,
      if (date != null) 'date': _formatDate(date),
    };
    final invokeCallable = _invokeCallable;
    if (invokeCallable != null) {
      return invokeCallable(_function, payload);
    }
    final functions = _functions ?? FirebaseFunctions.instance;
    final result = await functions.httpsCallable(_function).call(payload);
    return result.data;
  }
}
