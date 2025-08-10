import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';

sealed class FlightPreviewParams extends Equatable {}

class FlightPreviewAirports extends FlightPreviewParams {
  final Airport departure;
  final Airport arrival;

  FlightPreviewAirports({required this.departure, required this.arrival});

  @override
  List<Object?> get props => [departure, arrival];
}