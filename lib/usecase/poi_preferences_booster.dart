import 'package:flymap/entity/flight_poi_type.dart';
import 'package:flymap/entity/user_profile.dart';

class PoiPreferencesBooster {
  static const int maxBoost = 140;

  const PoiPreferencesBooster();

  static const Map<UsersInterests, Map<FlightPoiType, int>> _interestBoosts =
      <UsersInterests, Map<FlightPoiType, int>>{
        UsersInterests.mountains: <FlightPoiType, int>{
          FlightPoiType.volcano: 140,
          FlightPoiType.mountain: 120,
          FlightPoiType.glacier: 100,
          FlightPoiType.pass: 100,
        },
        UsersInterests.cities: <FlightPoiType, int>{
          FlightPoiType.city: 120,
          FlightPoiType.region: 80,
          FlightPoiType.airport: 35,
        },
        UsersInterests.coastlines: <FlightPoiType, int>{
          FlightPoiType.island: 120,
          FlightPoiType.bay: 100,
          FlightPoiType.sea: 80,
          FlightPoiType.river: 45,
          FlightPoiType.lake: 45,
        },
        UsersInterests.landmarks: <FlightPoiType, int>{
          FlightPoiType.city: 100,
          FlightPoiType.region: 90,
          FlightPoiType.waterfall: 80,
          FlightPoiType.lake: 45,
        },
        UsersInterests.aviationHistory: <FlightPoiType, int>{
          FlightPoiType.airport: 160,
          FlightPoiType.city: 40,
        },
        UsersInterests.engineering: <FlightPoiType, int>{
          FlightPoiType.airport: 145,
          FlightPoiType.city: 35,
          FlightPoiType.pass: 25,
        },
      };

  int interestBoostFor(FlightPoiType type, List<UsersInterests> interests) {
    if (interests.isEmpty) return 0;

    var maxInterestBoost = 0;
    for (final interest in interests) {
      final boost = _interestBoosts[interest]?[type] ?? 0;
      if (boost > maxInterestBoost) {
        maxInterestBoost = boost;
      }
    }
    return maxInterestBoost.clamp(0, maxBoost);
  }
}
