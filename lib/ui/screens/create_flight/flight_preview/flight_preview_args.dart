import 'package:flymap/entity/airport.dart';

class FlightPreviewArgs {
  const FlightPreviewArgs({required this.departure, required this.arrival});

  final Airport departure;
  final Airport arrival;
}
