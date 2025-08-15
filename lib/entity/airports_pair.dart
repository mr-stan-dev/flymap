import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';

class AirportsPair extends Equatable {
  final Airport departure;
  final Airport arrival;

  const AirportsPair({required this.departure, required this.arrival});

  @override
  List<Object?> get props => [departure, arrival];
}
