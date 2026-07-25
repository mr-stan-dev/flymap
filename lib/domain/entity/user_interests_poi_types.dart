import 'package:flymap/domain/entity/flight_poi_type.dart';
import 'package:flymap/domain/entity/user_profile.dart';

/// Place types covered by each interest topic. Used to boost matching POIs
/// in tier selection and to group counts on the onboarding payoff step.
extension UsersInterestsPoiTypes on UsersInterests {
  Set<FlightPoiType> get poiTypes {
    return switch (this) {
      UsersInterests.mountains => const {
        FlightPoiType.mountain,
        FlightPoiType.pass,
        FlightPoiType.glacier,
      },
      UsersInterests.volcanoes => const {FlightPoiType.volcano},
      UsersInterests.regions => const {
        FlightPoiType.city,
        FlightPoiType.region,
      },
      UsersInterests.islands => const {
        FlightPoiType.island,
        FlightPoiType.bay,
        FlightPoiType.sea,
      },
      UsersInterests.nationalParks => const {
        FlightPoiType.park,
        FlightPoiType.reserve,
      },
      UsersInterests.rivers => const {
        FlightPoiType.river,
        FlightPoiType.lake,
        FlightPoiType.waterfall,
      },
    };
  }
}
