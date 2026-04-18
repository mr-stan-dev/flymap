import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test(
    'buildFlightInfoFunctionRequest includes user_preferences.interests',
    () {
      final request = buildFlightInfoFunctionRequest(
        airportDeparture: 'LHR',
        airportArrival: 'SFO',
        waypoints: const [LatLng(0, 0), LatLng(1, 1)],
        promptVersion: 2,
        interests: const [UsersInterests.cities, UsersInterests.engineering],
      );

      expect(request['user_preferences'], isA<Map<String, dynamic>>());
      final prefs = request['user_preferences']! as Map<String, dynamic>;
      expect(prefs['interests'], ['cities', 'engineering']);
    },
  );

  test('buildFlightInfoFunctionRequest omits user_preferences when empty', () {
    final request = buildFlightInfoFunctionRequest(
      airportDeparture: 'LHR',
      airportArrival: 'SFO',
      waypoints: const [LatLng(0, 0), LatLng(1, 1)],
      promptVersion: 2,
      interests: const [],
    );

    expect(request.containsKey('user_preferences'), isFalse);
  });
}
