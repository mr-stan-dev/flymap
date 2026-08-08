import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/flight_route_preview_api.dart';

void main() {
  test(
    'opts out of summary lookup when an FR24 ID is already selected',
    () async {
      String? calledFunction;
      Map<String, dynamic>? calledPayload;
      final api = FlightRoutePreviewApi(
        invokeCallable: (function, payload) async {
          calledFunction = function;
          calledPayload = payload;
          return <String, dynamic>{'ok': true};
        },
      );

      await api.buildFlightRoutePreview(
        flightNumber: ' ba 117 ',
        fr24Id: ' track-123 ',
        origCode: ' egll ',
        destCode: ' kjfk ',
        placesLimit: 200,
        regionsLimit: 50,
      );

      expect(calledFunction, 'build_flight_route_preview');
      expect(calledPayload, <String, dynamic>{
        'flightNumber': 'BA117',
        'fr24Id': 'track-123',
        'skipSummaryLookup': true,
        'origCode': 'EGLL',
        'destCode': 'KJFK',
        'placesLimit': 200,
        'regionsLimit': 50,
        'lang': 'en',
      });
    },
  );

  test('keeps legacy summary lookup when no FR24 ID is available', () async {
    Map<String, dynamic>? calledPayload;
    final api = FlightRoutePreviewApi(
      invokeCallable: (_, payload) async {
        calledPayload = payload;
        return <String, dynamic>{'ok': true};
      },
    );

    await api.buildFlightRoutePreview(
      flightNumber: 'BA117',
      placesLimit: 200,
      regionsLimit: 50,
    );

    expect(calledPayload?.containsKey('skipSummaryLookup'), isFalse);
    expect(calledPayload?.containsKey('fr24Id'), isFalse);
  });
}
