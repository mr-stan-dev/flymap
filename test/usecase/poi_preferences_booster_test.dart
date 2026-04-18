import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/usecase/poi_preferences_booster.dart';

void main() {
  const booster = PoiPreferencesBooster();

  test('returns zero boost when no interests provided', () {
    final boost = booster.interestBoostFor(FlightPoiType.mountain, const []);
    expect(boost, 0);
  });

  test('uses maximum matching interest boost instead of summing', () {
    final boost = booster.interestBoostFor(FlightPoiType.city, const [
      UsersInterests.cities,
      UsersInterests.landmarks,
    ]);
    expect(boost, 120);
  });

  test('applies hard cap to keep boosts bounded', () {
    final boost = booster.interestBoostFor(FlightPoiType.airport, const [
      UsersInterests.engineering,
      UsersInterests.aviationHistory,
    ]);
    expect(boost, PoiPreferencesBooster.maxBoost);
    expect(boost, 140);
  });
}
