import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/upcoming_flight_search_api.dart';

void main() {
  test('opts out of redundant FR24 stitching on compatible backends', () async {
    String? calledFunction;
    Map<String, dynamic>? calledPayload;
    final api = UpcomingFlightSearchApi(
      invokeCallable: (function, payload) async {
        calledFunction = function;
        calledPayload = payload;
        return <String, dynamic>{'flights': <Map<String, dynamic>>[]};
      },
    );

    await api.searchUpcomingFlightsByNumber(
      ' ba 117 ',
      date: DateTime(2026, 8, 9),
    );

    expect(calledFunction, 'search_upcoming_flights_by_number');
    expect(calledPayload, <String, dynamic>{
      'flightNumber': 'BA117',
      'includeHistorical': false,
      'date': '2026-08-09',
    });
  });
}
