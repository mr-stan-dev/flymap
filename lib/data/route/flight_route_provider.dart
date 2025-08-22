import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_route.dart';

abstract interface class FlightRouteProvider {
  FlightRoute getRoute({required Airport departure, required Airport arrival});
}
