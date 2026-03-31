import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';

class FlightSearchStepMeta {
  static String titleForStep(CreateFlightStep step) {
    switch (step) {
      case CreateFlightStep.departure:
        return 'Choose departure airport';
      case CreateFlightStep.arrival:
        return 'Choose arrival airport';
      case CreateFlightStep.mapPreview:
        return 'Map preview';
      case CreateFlightStep.overview:
        return 'Route overview';
      case CreateFlightStep.wikipediaArticles:
        return 'Wikipedia articles';
    }
  }

  static int indexForStep(CreateFlightStep step) {
    switch (step) {
      case CreateFlightStep.departure:
        return 0;
      case CreateFlightStep.arrival:
        return 1;
      case CreateFlightStep.mapPreview:
        return 2;
      case CreateFlightStep.overview:
        return 3;
      case CreateFlightStep.wikipediaArticles:
        return 4;
    }
  }
}

List<Airport> filterAirportsForCurrentStep(
  List<Airport> airports,
  FlightSearchScreenState state,
) {
  if (state.step != CreateFlightStep.arrival) return airports;

  final departureCode = airportCode(state.selectedDeparture);
  if (departureCode.isEmpty) return airports;

  return airports
      .where((airport) => airportCode(airport) != departureCode)
      .toList();
}

String airportCode(Airport? airport) {
  if (airport == null) return '';

  final primary = airport.primaryCode.trim().toUpperCase();
  if (primary.isNotEmpty) return primary;

  return airport.displayCode.trim().toUpperCase();
}
