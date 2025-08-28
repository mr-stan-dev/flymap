import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight.dart';

sealed class FlightSearchScreenState extends Equatable {
  const FlightSearchScreenState();

  @override
  List<Object?> get props => [];
}

final class FlightSearchInitial extends FlightSearchScreenState {
  const FlightSearchInitial();
}

final class FlightSearchByAirports extends FlightSearchScreenState {
  final Airport departure;
  final Airport arrival;

  const FlightSearchByAirports({
    required this.departure,
    required this.arrival,
  });

  @override
  List<Object?> get props => [departure, arrival];
}

final class FlightSearchByAirportsLoading extends FlightSearchScreenState {
  final Airport departure;
  final Airport arrival;

  const FlightSearchByAirportsLoading({
    required this.departure,
    required this.arrival,
  });

  @override
  List<Object?> get props => [departure, arrival];
}

final class FlightSearchByAirportsResults extends FlightSearchScreenState {
  final Airport departure;
  final Airport arrival;
  final List<Flight> flights;

  const FlightSearchByAirportsResults({
    required this.departure,
    required this.arrival,
    required this.flights,
  });

  @override
  List<Object?> get props => [departure, arrival, flights];
}

final class FlightSearchByAirportsNoResults extends FlightSearchScreenState {
  final Airport departure;
  final Airport arrival;

  const FlightSearchByAirportsNoResults({
    required this.departure,
    required this.arrival,
  });

  @override
  List<Object?> get props => [departure, arrival];
}

final class FlightSearchError extends FlightSearchScreenState {
  final String message;

  const FlightSearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Airport Search States
final class AirportSearchLoading extends FlightSearchScreenState {
  const AirportSearchLoading();
}

final class AirportSearchResults extends FlightSearchScreenState {
  final List<Airport> airports;

  const AirportSearchResults({required this.airports});

  @override
  List<Object?> get props => [airports];
}

final class AirportSearchNoResults extends FlightSearchScreenState {
  const AirportSearchNoResults();
}
