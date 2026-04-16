import 'package:flymap/entity/flight_poi_type.dart';

class RoutePoiRank {
  RoutePoiRank._();

  static int typeInterestBoost(FlightPoiType type) => switch (type) {
    FlightPoiType.volcano => 500,
    FlightPoiType.glacier => 450,
    FlightPoiType.waterfall => 400,
    FlightPoiType.mountain => 350,
    FlightPoiType.island => 350,
    FlightPoiType.lake => 300,
    FlightPoiType.desert => 200,
    FlightPoiType.bay => 150,
    FlightPoiType.sea => 100,
    FlightPoiType.river => 100,
    FlightPoiType.city => 50,
    FlightPoiType.pass => 50,
    FlightPoiType.airport => 50,
    FlightPoiType.region => 0,
    FlightPoiType.unknown => 0,
  };

  static int baseScore({required FlightPoiType type, required int sitelinks}) {
    return sitelinks + typeInterestBoost(type);
  }
}
