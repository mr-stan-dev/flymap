import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';

enum CreateFlightStep { departure, arrival, mapPreview, overview }

class FlightSearchScreenState extends Equatable {
  const FlightSearchScreenState({
    required this.step,
    required this.popularAirports,
    required this.favoriteAirports,
    required this.searchQuery,
    required this.searchResults,
    required this.isSearchLoading,
    required this.selectedDeparture,
    required this.selectedArrival,
    required this.selectedAirportIsFavorite,
    required this.flightRoute,
    required this.flightInfo,
    required this.isPreviewLoading,
    required this.isOverviewLoading,
    required this.isTooLongFlight,
    required this.isDownloading,
    required this.downloadProgress,
    required this.downloadDone,
    required this.errorMessage,
    required this.downloadErrorMessage,
  });

  factory FlightSearchScreenState.initial() {
    return const FlightSearchScreenState(
      step: CreateFlightStep.departure,
      popularAirports: [],
      favoriteAirports: [],
      searchQuery: '',
      searchResults: [],
      isSearchLoading: false,
      selectedDeparture: null,
      selectedArrival: null,
      selectedAirportIsFavorite: false,
      flightRoute: null,
      flightInfo: FlightInfo.empty,
      isPreviewLoading: false,
      isOverviewLoading: false,
      isTooLongFlight: false,
      isDownloading: false,
      downloadProgress: 0.0,
      downloadDone: false,
      errorMessage: null,
      downloadErrorMessage: null,
    );
  }

  final CreateFlightStep step;
  final List<Airport> popularAirports;
  final List<Airport> favoriteAirports;
  final String searchQuery;
  final List<Airport> searchResults;
  final bool isSearchLoading;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final bool selectedAirportIsFavorite;
  final FlightRoute? flightRoute;
  final FlightInfo flightInfo;
  final bool isPreviewLoading;
  final bool isOverviewLoading;
  final bool isTooLongFlight;
  final bool isDownloading;
  final double downloadProgress;
  final bool downloadDone;
  final String? errorMessage;
  final String? downloadErrorMessage;

  bool get canContinueFromMap =>
      flightRoute != null &&
      !isPreviewLoading &&
      !isDownloading &&
      !isTooLongFlight;

  FlightSearchScreenState copyWith({
    CreateFlightStep? step,
    List<Airport>? popularAirports,
    List<Airport>? favoriteAirports,
    String? searchQuery,
    List<Airport>? searchResults,
    bool? isSearchLoading,
    Airport? selectedDeparture,
    bool clearSelectedDeparture = false,
    Airport? selectedArrival,
    bool clearSelectedArrival = false,
    bool? selectedAirportIsFavorite,
    FlightRoute? flightRoute,
    bool clearFlightRoute = false,
    FlightInfo? flightInfo,
    bool? isPreviewLoading,
    bool? isOverviewLoading,
    bool? isTooLongFlight,
    bool? isDownloading,
    double? downloadProgress,
    bool? downloadDone,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? downloadErrorMessage,
    bool clearDownloadErrorMessage = false,
  }) {
    return FlightSearchScreenState(
      step: step ?? this.step,
      popularAirports: popularAirports ?? this.popularAirports,
      favoriteAirports: favoriteAirports ?? this.favoriteAirports,
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
      flightRoute: clearFlightRoute ? null : flightRoute ?? this.flightRoute,
      flightInfo: flightInfo ?? this.flightInfo,
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      isTooLongFlight: isTooLongFlight ?? this.isTooLongFlight,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadDone: downloadDone ?? this.downloadDone,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      downloadErrorMessage: clearDownloadErrorMessage
          ? null
          : downloadErrorMessage ?? this.downloadErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    step,
    popularAirports,
    favoriteAirports,
    searchQuery,
    searchResults,
    isSearchLoading,
    selectedDeparture,
    selectedArrival,
    selectedAirportIsFavorite,
    flightRoute,
    flightInfo,
    isPreviewLoading,
    isOverviewLoading,
    isTooLongFlight,
    isDownloading,
    downloadProgress,
    downloadDone,
    errorMessage,
    downloadErrorMessage,
  ];
}
