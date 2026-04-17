import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/viewmodel/airport_selection_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/popular_flights.dart';

class AirportSelectionScreenCubit extends Cubit<AirportSelectionScreenState> {
  AirportSelectionScreenCubit({
    required AirportsDatabase airportsDb,
    required FavoriteAirportsRepository favoritesRepository,
    required OnboardingRepository onboardingRepository,
    required RecentAirportsRepository recentAirportsRepository,
    bool autoInitialize = true,
  }) : _airportsDb = airportsDb,
       _favoritesRepository = favoritesRepository,
       _onboardingRepository = onboardingRepository,
       _recentAirportsRepository = recentAirportsRepository,
       super(AirportSelectionScreenState.initial()) {
    if (autoInitialize) {
      _initialize();
    }
  }

  final AirportsDatabase _airportsDb;
  final FavoriteAirportsRepository _favoritesRepository;
  final OnboardingRepository _onboardingRepository;
  final RecentAirportsRepository _recentAirportsRepository;
  final _logger = Logger('AirportSelectionScreenCubit');

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
          searchResults: const [],
          isSearchLoading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      _logger.error('Failed to initialize airport selection: $e');
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
          searchResults: const [],
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
          searchResults: const [],
          errorMessage: t.createFlight.errors.airportSearchFailed,
        ),
      );
    }
  }

  Future<void> selectAirport(Airport airport) async {
    if (state.step == AirportSelectionStep.arrival &&
        _sameAirportAsDeparture(airport)) {
      return;
    }

    final isFavorite = await _isFavorite(airport);
    switch (state.step) {
      case AirportSelectionStep.departure:
        emit(
          state.copyWith(
            selectedDeparture: airport,
            clearSelectedArrival: true,
            selectedAirportIsFavorite: isFavorite,
            searchQuery: _airportSearchLabel(airport),
            searchResults: const [],
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
            searchResults: const [],
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
    switch (state.step) {
      case AirportSelectionStep.departure:
        emit(
          state.copyWith(
            clearSelectedDeparture: true,
            selectedAirportIsFavorite: false,
            searchQuery: '',
            searchResults: const [],
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
            searchResults: const [],
            isSearchLoading: false,
            clearErrorMessage: true,
          ),
        );
        break;
    }
  }

  Future<void> continueFromAirportStep() async {
    switch (state.step) {
      case AirportSelectionStep.departure:
        final departure = state.selectedDeparture;
        if (departure == null) return;
        await _touchFavoriteIfNeeded(departure);
        emit(
          state.copyWith(
            step: AirportSelectionStep.arrival,
            searchQuery: '',
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: false,
            clearSelectedArrival: true,
            clearErrorMessage: true,
          ),
        );
        break;
      case AirportSelectionStep.arrival:
        break;
    }
  }

  Future<void> saveSelectedAirportsAsRecent() async {
    final departureCode = _airportCode(state.selectedDeparture);
    final arrivalCode = _airportCode(state.selectedArrival);
    await _recentAirportsRepository.addRecents([departureCode, arrivalCode]);
    final recentAirports = await _loadRecentAirports();
    emit(state.copyWith(recentAirports: recentAirports));
  }

  Future<bool> handleBackAction() async {
    switch (state.step) {
      case AirportSelectionStep.departure:
        return true;
      case AirportSelectionStep.arrival:
        final departureIsFavorite = await _isFavorite(state.selectedDeparture);
        final departureSearchLabel = state.selectedDeparture == null
            ? ''
            : _airportSearchLabel(state.selectedDeparture!);
        emit(
          state.copyWith(
            step: AirportSelectionStep.departure,
            searchQuery: departureSearchLabel,
            searchResults: const [],
            isSearchLoading: false,
            selectedAirportIsFavorite: departureIsFavorite,
            clearErrorMessage: true,
          ),
        );
        return false;
    }
  }

  List<Airport> _applyStepAirportFilter(List<Airport> airports) {
    if (state.step != AirportSelectionStep.arrival) return airports;

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
}
