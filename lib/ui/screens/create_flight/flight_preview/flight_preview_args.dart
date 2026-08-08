import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';

class FlightPreviewArgs {
  const FlightPreviewArgs({
    required this.departure,
    required this.arrival,
    this.flightNumber,
    this.fr24Id,
    this.airlineCodeHint,
    this.airlineNameHint,
    this.schedule,
    this.hasPendingFlightUnlock = false,
  });

  final Airport departure;
  final Airport arrival;
  final String? flightNumber;
  final String? fr24Id;
  final String? airlineCodeHint;
  final String? airlineNameHint;

  /// Schedule picked in the search step; null for dateless flights (a complete
  /// manual date and time can still be added on the weather step).
  final FlightSchedule? schedule;
  final bool hasPendingFlightUnlock;
}
