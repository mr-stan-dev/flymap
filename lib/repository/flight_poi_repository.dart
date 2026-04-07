import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/route_poi.dart';

abstract interface class FlightPOIRepository {
  Future<List<RoutePoi>> getRoutePois({
    required FlightRoute route,
    required int prefetchLimit,
  });
}
