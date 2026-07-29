import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/viewmodel/airport_selection_screen_state.dart';

enum RealRouteAirportSearchView { airportSelection, results }

class RealRouteAirportSearchState extends Equatable {
  const RealRouteAirportSearchState({
    required this.view,
    required this.airportStep,
    required this.popularAirports,
    required this.favoriteAirports,
    required this.recentAirports,
    required this.homeAirport,
    required this.searchQuery,
    required this.searchResults,
    required this.isSearchLoading,
    required this.isRouteSearchLoading,
    required this.selectedDeparture,
    required this.selectedArrival,
    required this.selectedAirportIsFavorite,
    required this.errorMessage,
    required this.routeSearchErrorMessage,
    required this.matchedFlights,
    required this.selectedMatchedFlight,
  });

  factory RealRouteAirportSearchState.initial() {
    return const RealRouteAirportSearchState(
      view: RealRouteAirportSearchView.airportSelection,
      airportStep: AirportSelectionStep.departure,
      popularAirports: <Airport>[],
      favoriteAirports: <Airport>[],
      recentAirports: <Airport>[],
      homeAirport: null,
      searchQuery: '',
      searchResults: <Airport>[],
      isSearchLoading: false,
      isRouteSearchLoading: false,
      selectedDeparture: null,
      selectedArrival: null,
      selectedAirportIsFavorite: false,
      errorMessage: null,
      routeSearchErrorMessage: null,
      matchedFlights: <FlightSummary>[],
      selectedMatchedFlight: null,
    );
  }

  final RealRouteAirportSearchView view;
  final AirportSelectionStep airportStep;
  final List<Airport> popularAirports;
  final List<Airport> favoriteAirports;
  final List<Airport> recentAirports;
  final Airport? homeAirport;
  final String searchQuery;
  final List<Airport> searchResults;
  final bool isSearchLoading;
  final bool isRouteSearchLoading;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final bool selectedAirportIsFavorite;
  final String? errorMessage;
  final String? routeSearchErrorMessage;
  final List<FlightSummary> matchedFlights;
  final FlightSummary? selectedMatchedFlight;

  Airport? get selectedAirport => airportStep == AirportSelectionStep.departure
      ? selectedDeparture
      : selectedArrival;

  RealRouteAirportSearchState copyWith({
    RealRouteAirportSearchView? view,
    AirportSelectionStep? airportStep,
    List<Airport>? popularAirports,
    List<Airport>? favoriteAirports,
    List<Airport>? recentAirports,
    Airport? homeAirport,
    bool clearHomeAirport = false,
    String? searchQuery,
    List<Airport>? searchResults,
    bool? isSearchLoading,
    bool? isRouteSearchLoading,
    Airport? selectedDeparture,
    bool clearSelectedDeparture = false,
    Airport? selectedArrival,
    bool clearSelectedArrival = false,
    bool? selectedAirportIsFavorite,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? routeSearchErrorMessage,
    bool clearRouteSearchErrorMessage = false,
    List<FlightSummary>? matchedFlights,
    FlightSummary? selectedMatchedFlight,
    bool clearSelectedMatchedFlight = false,
  }) {
    return RealRouteAirportSearchState(
      view: view ?? this.view,
      airportStep: airportStep ?? this.airportStep,
      popularAirports: popularAirports ?? this.popularAirports,
      favoriteAirports: favoriteAirports ?? this.favoriteAirports,
      recentAirports: recentAirports ?? this.recentAirports,
      homeAirport: clearHomeAirport ? null : homeAirport ?? this.homeAirport,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearchLoading: isSearchLoading ?? this.isSearchLoading,
      isRouteSearchLoading: isRouteSearchLoading ?? this.isRouteSearchLoading,
      selectedDeparture: clearSelectedDeparture
          ? null
          : selectedDeparture ?? this.selectedDeparture,
      selectedArrival: clearSelectedArrival
          ? null
          : selectedArrival ?? this.selectedArrival,
      selectedAirportIsFavorite:
          selectedAirportIsFavorite ?? this.selectedAirportIsFavorite,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      routeSearchErrorMessage: clearRouteSearchErrorMessage
          ? null
          : routeSearchErrorMessage ?? this.routeSearchErrorMessage,
      matchedFlights: matchedFlights ?? this.matchedFlights,
      selectedMatchedFlight: clearSelectedMatchedFlight
          ? null
          : selectedMatchedFlight ?? this.selectedMatchedFlight,
    );
  }

  @override
  List<Object?> get props => [
    view,
    airportStep,
    popularAirports,
    favoriteAirports,
    recentAirports,
    homeAirport,
    searchQuery,
    searchResults,
    isSearchLoading,
    isRouteSearchLoading,
    selectedDeparture,
    selectedArrival,
    selectedAirportIsFavorite,
    errorMessage,
    routeSearchErrorMessage,
    matchedFlights,
    selectedMatchedFlight,
  ];

  @override
  String toString() {
    return 'RealRouteAirportSearchState('
        'view:$view, '
        'step:$airportStep, '
        'searchLoading:$isSearchLoading, '
        'routeLoading:$isRouteSearchLoading, '
        'departure:${selectedDeparture?.primaryCode ?? '-'}, '
        'arrival:${selectedArrival?.primaryCode ?? '-'}, '
        'searchResults:${searchResults.length}, '
        'matchedFlights:${matchedFlights.length}, '
        'routeError:${routeSearchErrorMessage != null}, '
        'selection:${selectedMatchedFlight?.flightNumber ?? '-'}, '
        ')';
  }
}
