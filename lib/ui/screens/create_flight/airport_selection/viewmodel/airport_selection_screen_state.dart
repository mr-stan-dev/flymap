import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';

enum AirportSelectionStep { departure, arrival }

class AirportSelectionScreenState extends Equatable {
  const AirportSelectionScreenState({
    required this.step,
    required this.popularAirports,
    required this.favoriteAirports,
    required this.recentAirports,
    required this.homeAirport,
    required this.searchQuery,
    required this.searchResults,
    required this.isSearchLoading,
    required this.selectedDeparture,
    required this.selectedArrival,
    required this.selectedAirportIsFavorite,
    required this.errorMessage,
  });

  factory AirportSelectionScreenState.initial() {
    return const AirportSelectionScreenState(
      step: AirportSelectionStep.departure,
      popularAirports: [],
      favoriteAirports: [],
      recentAirports: [],
      homeAirport: null,
      searchQuery: '',
      searchResults: [],
      isSearchLoading: false,
      selectedDeparture: null,
      selectedArrival: null,
      selectedAirportIsFavorite: false,
      errorMessage: null,
    );
  }

  final AirportSelectionStep step;
  final List<Airport> popularAirports;
  final List<Airport> favoriteAirports;
  final List<Airport> recentAirports;
  final Airport? homeAirport;
  final String searchQuery;
  final List<Airport> searchResults;
  final bool isSearchLoading;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final bool selectedAirportIsFavorite;
  final String? errorMessage;

  Airport? get selectedAirport => step == AirportSelectionStep.departure
      ? selectedDeparture
      : selectedArrival;

  AirportSelectionScreenState copyWith({
    AirportSelectionStep? step,
    List<Airport>? popularAirports,
    List<Airport>? favoriteAirports,
    List<Airport>? recentAirports,
    Airport? homeAirport,
    bool clearHomeAirport = false,
    String? searchQuery,
    List<Airport>? searchResults,
    bool? isSearchLoading,
    Airport? selectedDeparture,
    bool clearSelectedDeparture = false,
    Airport? selectedArrival,
    bool clearSelectedArrival = false,
    bool? selectedAirportIsFavorite,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AirportSelectionScreenState(
      step: step ?? this.step,
      popularAirports: popularAirports ?? this.popularAirports,
      favoriteAirports: favoriteAirports ?? this.favoriteAirports,
      recentAirports: recentAirports ?? this.recentAirports,
      homeAirport: clearHomeAirport ? null : homeAirport ?? this.homeAirport,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearchLoading: isSearchLoading ?? this.isSearchLoading,
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
    );
  }

  @override
  List<Object?> get props => [
    step,
    popularAirports,
    favoriteAirports,
    recentAirports,
    homeAirport,
    searchQuery,
    searchResults,
    isSearchLoading,
    selectedDeparture,
    selectedArrival,
    selectedAirportIsFavorite,
    errorMessage,
  ];
}
