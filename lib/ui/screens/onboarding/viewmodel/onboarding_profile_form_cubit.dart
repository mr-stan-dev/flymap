import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/user_profile.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/ui/screens/create_flight/airport_selection/popular_flights.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';

class OnboardingProfileFormCubit extends Cubit<OnboardingProfileFormState> {
  OnboardingProfileFormCubit({
    required OnboardingRepository repository,
    required AirportsDatabase airportsDb,
    required FavoriteAirportsRepository favoritesRepository,
    required RecentAirportsRepository recentAirportsRepository,
    bool autoLoad = true,
  }) : _repository = repository,
       _airportsDb = airportsDb,
       _favoritesRepository = favoritesRepository,
       _recentAirportsRepository = recentAirportsRepository,
       super(const OnboardingProfileFormState.initial()) {
    if (autoLoad) {
      load();
    }
  }

  final OnboardingRepository _repository;
  final AirportsDatabase _airportsDb;
  final FavoriteAirportsRepository _favoritesRepository;
  final RecentAirportsRepository _recentAirportsRepository;
  final _logger = Logger('OnboardingProfileFormCubit');

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      await _airportsDb.initialize();
      final profile = await _repository.getProfile();
      final homeAirport = _findAirportByCode(profile.homeAirportCode);
      final favoriteAirports = await _loadFavoriteAirports();
      final recentAirports = await _loadRecentAirports();
      final popularAirports = await loadPopularAirports(
        airportsDatabase: _airportsDb,
      );
      emit(
        state.copyWith(
          isLoading: false,
          profile: profile,
          homeAirport: homeAirport,
          favoriteAirports: favoriteAirports,
          recentAirports: recentAirports,
          popularAirports: popularAirports,
          airportQuery: '',
          airportSearchResults: const [],
          isAirportSearchLoading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      _logger.error('Failed to load onboarding profile form: $error');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: t.onboarding.failedLoadProfile,
        ),
      );
    }
  }

  Future<void> setDisplayName(String value) async {
    await _persistProfile(state.profile.copyWith(displayName: value));
  }

  Future<void> setFlyingFrequency(FlyingFrequency frequency) async {
    await _persistProfile(state.profile.copyWith(flyingFrequency: frequency));
  }

  Future<void> toggleInterest(UsersInterests interest) async {
    final updated = [...state.profile.interests];
    if (updated.contains(interest)) {
      updated.remove(interest);
    } else {
      if (updated.length >= OnboardingProfileFormState.maxInterests) return;
      updated.add(interest);
    }
    await _persistProfile(state.profile.copyWith(interests: updated));
  }

  Future<void> setInterests(List<UsersInterests> interests) async {
    final capped = interests
        .take(OnboardingProfileFormState.maxInterests)
        .toList();
    await _persistProfile(state.profile.copyWith(interests: capped));
  }

  Future<void> searchHomeAirports(String query) async {
    final normalized = query.trim();
    emit(
      state.copyWith(
        airportQuery: query,
        isAirportSearchLoading: normalized.isNotEmpty,
        clearErrorMessage: true,
      ),
    );

    if (normalized.isEmpty) {
      emit(
        state.copyWith(
          airportSearchResults: const [],
          isAirportSearchLoading: false,
        ),
      );
      return;
    }

    try {
      final results = _airportsDb.search(normalized).take(20).toList();
      emit(
        state.copyWith(
          airportSearchResults: results,
          isAirportSearchLoading: false,
        ),
      );
    } catch (error) {
      _logger.error('Home airport search failed: $error');
      emit(
        state.copyWith(
          isAirportSearchLoading: false,
          airportSearchResults: const [],
          errorMessage: t.createFlight.errors.airportSearchFailed,
        ),
      );
    }
  }

  Future<void> selectHomeAirport(
    Airport airport, {
    bool addToFavorites = true,
  }) async {
    if (addToFavorites) {
      await _favoritesRepository.addFavorite(_airportCode(airport));
    }
    await _persistProfile(
      state.profile.copyWith(homeAirportCode: _airportCode(airport)),
      homeAirport: airport,
      airportQuery: '${airport.name} (${airport.displayCode})',
      airportSearchResults: const [],
    );
    if (addToFavorites) {
      await _refreshReferenceAirports();
    }
  }

  Future<void> clearHomeAirport() async {
    await _persistProfile(
      state.profile.copyWith(clearHomeAirportCode: true),
      clearHomeAirport: true,
      airportQuery: '',
      airportSearchResults: const [],
    );
  }

  Future<void> completeOnboarding() async {
    await _repository.markSeen();
  }

  Future<void> addSelectedHomeAirportToFavorites() async {
    final airport = state.homeAirport;
    if (airport == null) return;
    await _favoritesRepository.addFavorite(_airportCode(airport));
    await _refreshReferenceAirports();
  }

  Future<void> refreshReferenceAirports() async {
    await _refreshReferenceAirports();
  }

  Future<void> _persistProfile(
    UserProfile profile, {
    Airport? homeAirport,
    bool clearHomeAirport = false,
    String? airportQuery,
    List<Airport>? airportSearchResults,
  }) async {
    emit(
      state.copyWith(
        profile: profile,
        homeAirport: homeAirport,
        clearHomeAirport: clearHomeAirport,
        airportQuery: airportQuery,
        airportSearchResults: airportSearchResults,
        clearErrorMessage: true,
      ),
    );
    await _repository.saveProfile(profile);
  }

  Future<void> _refreshReferenceAirports() async {
    final favoriteAirports = await _loadFavoriteAirports();
    final recentAirports = await _loadRecentAirports();
    emit(
      state.copyWith(
        favoriteAirports: favoriteAirports,
        recentAirports: recentAirports,
      ),
    );
  }

  Future<List<Airport>> _loadFavoriteAirports() async {
    final favoriteCodes = await _favoritesRepository.getFavoriteCodes();
    return _resolveCodes(favoriteCodes);
  }

  Future<List<Airport>> _loadRecentAirports() async {
    final recentCodes = await _recentAirportsRepository.getRecentCodes();
    return _resolveCodes(recentCodes);
  }

  List<Airport> _resolveCodes(List<String> codes) {
    final airports = <Airport>[];
    for (final code in codes) {
      final airport = _findAirportByCode(code);
      if (airport != null) {
        airports.add(airport);
      }
    }
    return airports;
  }

  Airport? _findAirportByCode(String? code) {
    final normalized = _normalizeCode(code);
    if (normalized == null) return null;
    return _airportsDb.findByCode(normalized);
  }

  String _airportCode(Airport airport) {
    final primary = airport.primaryCode.trim().toUpperCase();
    if (primary.isNotEmpty) return primary;
    return airport.displayCode.trim().toUpperCase();
  }

  String? _normalizeCode(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toUpperCase();
    return normalized.isEmpty ? null : normalized;
  }
}
