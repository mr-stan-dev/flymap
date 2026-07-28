import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_summary.dart';
import 'package:flymap/domain/usecase/search_flights_by_route_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/popular_flights.dart';
import 'package:flymap/ui/screens/create_flight/airports_search/viewmodel/airport_selection_screen_state.dart';

import 'real_route_airport_search_state.dart';

class RealRouteAirportSearchCubit extends Cubit<RealRouteAirportSearchState> {
  RealRouteAirportSearchCubit({
    required AirportsDatabase airportsDb,
    required FavoriteAirportsRepository favoritesRepository,
    required OnboardingRepository onboardingRepository,
    required RecentAirportsRepository recentAirportsRepository,
    required SearchFlightsByRouteUseCase searchFlightsByRouteUseCase,
    bool autoInitialize = true,
  }) : _airportsDb = airportsDb,
       _favoritesRepository = favoritesRepository,
       _onboardingRepository = onboardingRepository,
       _recentAirportsRepository = recentAirportsRepository,
       _searchFlightsByRouteUseCase = searchFlightsByRouteUseCase,
       super(RealRouteAirportSearchState.initial()) {
    if (autoInitialize) {
      _initialize();
    }
  }

  final AirportsDatabase _airportsDb;
  final FavoriteAirportsRepository _favoritesRepository;
  final OnboardingRepository _onboardingRepository;
  final RecentAirportsRepository _recentAirportsRepository;
  final SearchFlightsByRouteUseCase _searchFlightsByRouteUseCase;
  final _logger = Logger('RealRouteAirportSearchCubit');

  Future<void> _initialize() async {
    try {
      await _airportsDb.initialize();
      final popularAirports = await loadPopularAirports(
        airportsDatabase: _airportsDb,
      );
      final favoriteAirports = await _loadFavoriteAirports();
      final recentAirports = await _loadRecentAirports();
      final homeAirport = await _loadHomeAirport();
      final prefillIsFavorite = await _isFavorite(homeAirport);
      final prefillQuery = homeAirport == null
          ? ''
          : _airportSearchLabel(homeAirport);

      emit(
        state.copyWith(
          popularAirports: popularAirports,
          favoriteAirports: favoriteAirports,
          recentAirports: recentAirports,
          homeAirport: homeAirport,
          selectedDeparture: homeAirport,
          selectedAirportIsFavorite: prefillIsFavorite,
          searchQuery: prefillQuery,
          searchResults: const <Airport>[],
          isSearchLoading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      _logger.error('Failed to initialize real route airport search: $e');
      emit(
        state.copyWith(errorMessage: t.createFlight.errors.failedLoadAirports),
      );
    }
  }

  Future<void> searchAirports(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      emit(
        state.copyWith(
          searchQuery: '',
          searchResults: const <Airport>[],
          isSearchLoading: false,
          clearErrorMessage: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        searchQuery: normalized,
        isSearchLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final results = _airportsDb.search(normalized).take(20).toList();
      emit(
        state.copyWith(
          searchQuery: normalized,
          searchResults: _applyStepAirportFilter(results),
          isSearchLoading: false,
        ),
      );
    } catch (e) {
      _logger.error('Airport search failed: $e');
      emit(
        state.copyWith(
          isSearchLoading: false,
          searchResults: const <Airport>[],
          errorMessage: t.createFlight.errors.airportSearchFailed,
        ),
      );
    }
  }

  Future<void> selectAirport(Airport airport) async {
    if (state.airportStep == AirportSelectionStep.arrival &&
        _sameAirportAsDeparture(airport)) {
      return;
    }

    final isFavorite = await _isFavorite(airport);
    switch (state.airportStep) {
      case AirportSelectionStep.departure:
        emit(
          state.copyWith(
            selectedDeparture: airport,
            clearSelectedArrival: true,
            selectedAirportIsFavorite: isFavorite,
            searchQuery: _airportSearchLabel(airport),
            searchResults: const <Airport>[],
            isSearchLoading: false,
            clearErrorMessage: true,
          ),
        );
        break;
      case AirportSelectionStep.arrival:
        emit(
          state.copyWith(
            selectedArrival: airport,
            selectedAirportIsFavorite: isFavorite,
            searchQuery: _airportSearchLabel(airport),
            searchResults: const <Airport>[],
            isSearchLoading: false,
            clearErrorMessage: true,
          ),
        );
        break;
    }
  }

  Future<void> toggleFavoriteForSelectedAirport() async {
    final airport = state.selectedAirport;
    if (airport == null) return;

    final code = _airportCode(airport);
    if (code.isEmpty) return;

    await _favoritesRepository.toggleFavorite(code);
    final isFavorite = await _favoritesRepository.isFavorite(code);
    await _refreshFavorites();
    emit(state.copyWith(selectedAirportIsFavorite: isFavorite));
  }

  Future<void> toggleFavoriteForAirport(Airport airport) async {
    final code = _airportCode(airport);
    if (code.isEmpty) return;

    await _favoritesRepository.toggleFavorite(code);
    final isFavorite = await _favoritesRepository.isFavorite(code);
    await _refreshFavorites();

    if (_airportCode(state.selectedAirport) == code) {
      emit(state.copyWith(selectedAirportIsFavorite: isFavorite));
    }
  }

  void clearSelectedAirportForCurrentStep() {
    switch (state.airportStep) {
      case AirportSelectionStep.departure:
        emit(
          state.copyWith(
            clearSelectedDeparture: true,
            selectedAirportIsFavorite: false,
            searchQuery: '',
            searchResults: const <Airport>[],
            isSearchLoading: false,
            clearErrorMessage: true,
          ),
        );
        break;
      case AirportSelectionStep.arrival:
        emit(
          state.copyWith(
            clearSelectedArrival: true,
            selectedAirportIsFavorite: false,
            searchQuery: '',
            searchResults: const <Airport>[],
            isSearchLoading: false,
            clearErrorMessage: true,
          ),
        );
        break;
    }
  }

  Future<void> continueFromAirportStep() async {
    switch (state.airportStep) {
      case AirportSelectionStep.departure:
        final departure = state.selectedDeparture;
        if (departure == null) return;
        await _touchFavoriteIfNeeded(departure);
        emit(
          state.copyWith(
            airportStep: AirportSelectionStep.arrival,
            searchQuery: '',
            searchResults: const <Airport>[],
            isSearchLoading: false,
            selectedAirportIsFavorite: false,
            clearSelectedArrival: true,
            clearErrorMessage: true,
          ),
        );
        break;
      case AirportSelectionStep.arrival:
        await searchFlights();
        break;
    }
  }

  Future<void> searchFlights() async {
    final departure = state.selectedDeparture;
    final arrival = state.selectedArrival;
    if (departure == null || arrival == null) return;

    await saveSelectedAirportsAsRecent();
    emit(
      state.copyWith(
        isRouteSearchLoading: true,
        view: RealRouteAirportSearchView.results,
        matchedFlights: const <FlightSummary>[],
        clearSelectedMatchedFlight: true,
        clearRouteSearchErrorMessage: true,
      ),
    );

    try {
      final flights = await _searchFlightsByRouteUseCase.call(
        departureCode: departure.primaryCode,
        arrivalCode: arrival.primaryCode,
      );

      emit(
        state.copyWith(
          view: RealRouteAirportSearchView.results,
          isRouteSearchLoading: false,
          matchedFlights: flights,
          // Preselect the top (most recent) candidate so a single tap on
          // Continue works; users can still switch.
          selectedMatchedFlight: flights.isEmpty ? null : flights.first,
          clearSelectedMatchedFlight: flights.isEmpty,
          clearRouteSearchErrorMessage: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          view: RealRouteAirportSearchView.results,
          isRouteSearchLoading: false,
          matchedFlights: const <FlightSummary>[],
          clearSelectedMatchedFlight: true,
          routeSearchErrorMessage: _searchFlightsFailureMessage(error),
        ),
      );
    }
  }

  void selectFlight(FlightSummary flight) {
    emit(state.copyWith(selectedMatchedFlight: flight));
  }

  /// Re-runs the route search with departure and arrival swapped — offered on
  /// empty results, where a mixed-up direction is a common cause.
  Future<void> searchReverseDirection() async {
    final departure = state.selectedDeparture;
    final arrival = state.selectedArrival;
    if (departure == null || arrival == null) return;
    emit(
      state.copyWith(selectedDeparture: arrival, selectedArrival: departure),
    );
    await searchFlights();
  }

  /// Candidate confirmed — the date is picked on the dedicated travel-date
  /// step, which the screen navigates to via [pendingSelection].
  void confirmSelectedFlight() {
    final flight = state.selectedMatchedFlight;
    if (flight == null) return;

    final normalizedFlightNumber = _normalizeFlightNumber(flight.flightNumber);
    final departure = flight.departure ?? state.selectedDeparture;
    final arrival = flight.arrival ?? state.selectedArrival;
    if (normalizedFlightNumber == null ||
        departure == null ||
        arrival == null) {
      return;
    }

    emit(
      state.copyWith(
        pendingSelection: RealRouteAirportSelection(
          flightNumber: normalizedFlightNumber,
          fr24Id: flight.fr24Id,
          departure: departure,
          arrival: arrival,
        ),
      ),
    );
  }

  void clearPendingSelection() {
    if (state.pendingSelection == null) return;
    emit(state.copyWith(clearPendingSelection: true));
  }

  Future<void> saveSelectedAirportsAsRecent() async {
    final departureCode = _airportCode(state.selectedDeparture);
    final arrivalCode = _airportCode(state.selectedArrival);
    await _recentAirportsRepository.addRecents([departureCode, arrivalCode]);
    final recentAirports = await _loadRecentAirports();
    emit(state.copyWith(recentAirports: recentAirports));
  }

  Future<void> reopenArrivalSelection({
    String query = '',
    bool clearSelectedAirport = false,
  }) async {
    final normalizedQuery = query.trim();
    final arrivalIsFavorite = clearSelectedAirport
        ? false
        : await _isFavorite(state.selectedArrival);
    final arrivalSearchLabel =
        clearSelectedAirport || state.selectedArrival == null
        ? ''
        : _airportSearchLabel(state.selectedArrival!);

    emit(
      state.copyWith(
        view: RealRouteAirportSearchView.airportSelection,
        airportStep: AirportSelectionStep.arrival,
        searchQuery: normalizedQuery.isNotEmpty
            ? normalizedQuery
            : arrivalSearchLabel,
        searchResults: const <Airport>[],
        isSearchLoading: false,
        isRouteSearchLoading: false,
        selectedAirportIsFavorite: arrivalIsFavorite,
        matchedFlights: const <FlightSummary>[],
        clearSelectedMatchedFlight: true,
        clearRouteSearchErrorMessage: true,
        clearPendingSelection: true,
        clearErrorMessage: true,
        clearSelectedArrival: clearSelectedAirport,
      ),
    );

    if (normalizedQuery.isNotEmpty) {
      await searchAirports(normalizedQuery);
    }
  }

  Future<bool> handleBackAction() async {
    if (state.view == RealRouteAirportSearchView.results) {
      await reopenArrivalSelection();
      return false;
    }

    switch (state.airportStep) {
      case AirportSelectionStep.departure:
        return true;
      case AirportSelectionStep.arrival:
        final departureIsFavorite = await _isFavorite(state.selectedDeparture);
        final departureSearchLabel = state.selectedDeparture == null
            ? ''
            : _airportSearchLabel(state.selectedDeparture!);
        emit(
          state.copyWith(
            airportStep: AirportSelectionStep.departure,
            searchQuery: departureSearchLabel,
            searchResults: const <Airport>[],
            isSearchLoading: false,
            selectedAirportIsFavorite: departureIsFavorite,
            clearErrorMessage: true,
          ),
        );
        return false;
    }
  }

  List<Airport> _applyStepAirportFilter(List<Airport> airports) {
    if (state.airportStep != AirportSelectionStep.arrival) return airports;

    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return airports;

    return airports
        .where((airport) => _airportCode(airport) != departureCode)
        .toList();
  }

  bool _sameAirportAsDeparture(Airport airport) {
    final departureCode = _airportCode(state.selectedDeparture);
    if (departureCode.isEmpty) return false;
    return _airportCode(airport) == departureCode;
  }

  Future<void> _touchFavoriteIfNeeded(Airport airport) async {
    final code = _airportCode(airport);
    if (code.isEmpty) return;

    final isFavorite = await _favoritesRepository.isFavorite(code);
    if (!isFavorite) return;
    await _favoritesRepository.touchFavorite(code);
    await _refreshFavorites();
  }

  Future<bool> _isFavorite(Airport? airport) async {
    final code = _airportCode(airport);
    if (code.isEmpty) return false;
    return _favoritesRepository.isFavorite(code);
  }

  Future<void> _refreshFavorites() async {
    final favoriteAirports = await _loadFavoriteAirports();
    emit(state.copyWith(favoriteAirports: favoriteAirports));
  }

  Future<List<Airport>> _loadFavoriteAirports() async {
    final favoriteCodes = await _favoritesRepository.getFavoriteCodes();
    final airports = <Airport>[];
    for (final code in favoriteCodes) {
      final airport = _airportsDb.findByCode(code);
      if (airport != null) {
        airports.add(airport);
      }
    }
    return airports;
  }

  Future<List<Airport>> _loadRecentAirports() async {
    final recentCodes = await _recentAirportsRepository.getRecentCodes();
    final airports = <Airport>[];
    for (final code in recentCodes) {
      final airport = _airportsDb.findByCode(code);
      if (airport != null) {
        airports.add(airport);
      }
    }
    return airports;
  }

  Future<Airport?> _loadHomeAirport() async {
    final profile = await _onboardingRepository.getProfile();
    final code = profile.homeAirportCode;
    if (code == null || code.isEmpty) return null;
    return _airportsDb.findByCode(code);
  }

  String _airportCode(Airport? airport) {
    if (airport == null) return '';
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }

  String _airportSearchLabel(Airport airport) =>
      '${airport.nameShort} (${airport.displayCode})';

  String _searchFlightsFailureMessage(Object error) {
    final searchT = t.createFlight.realRouteAirportSearch;
    if (error is FirebaseFunctionsException) {
      return switch (error.code) {
        'not-found' => searchT.emptyResults,
        'resource-exhausted' => searchT.rateLimitedError,
        'unavailable' => searchT.providerUnavailableError,
        _ => searchT.unexpectedError,
      };
    }
    return searchT.unexpectedError;
  }

  String? _normalizeFlightNumber(String? raw) {
    if (raw == null) return null;
    final value = raw.replaceAll(RegExp(r'\s+'), '').trim().toUpperCase();
    return value.isEmpty ? null : value;
  }
}
