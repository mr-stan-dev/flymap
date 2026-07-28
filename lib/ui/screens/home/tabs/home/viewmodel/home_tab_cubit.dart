import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/domain/usecase/complete_flight_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';

/// Cubit for managing home tab state
class HomeTabCubit extends Cubit<HomeTabState> {
  final _logger = Logger('HomeTabCubit');
  final FlightRepository _repository;
  final OnboardingRepository _onboardingRepository;
  final DeleteFlightUseCase _deleteFlightUseCase;
  final CompleteFlightUseCase? _completeFlightUseCase;
  final ConnectivityChecker _connectivityChecker;
  final MetricUnitsRepository _unitsRepository;

  HomeFlightsSort _sort = HomeFlightsSort.mostRecent;
  List<Flight> _allFlights = const [];

  HomeTabCubit({
    required FlightRepository repository,
    required OnboardingRepository onboardingRepository,
    required DeleteFlightUseCase deleteFlightUseCase,
    CompleteFlightUseCase? completeFlightUseCase,
    ConnectivityChecker? connectivityChecker,
    MetricUnitsRepository? unitsRepository,
  }) : _repository = repository,
       _onboardingRepository = onboardingRepository,
       _deleteFlightUseCase = deleteFlightUseCase,
       _completeFlightUseCase = completeFlightUseCase,
       _connectivityChecker =
           connectivityChecker ?? const ConnectivityChecker(),
       _unitsRepository = unitsRepository ?? MetricUnitsRepository(),
       super(const HomeTabLoading()) {
    _loadData();
  }

  /// Load all data for home tab
  Future<void> _loadData() async {
    try {
      emit(const HomeTabLoading());

      // Load data in parallel
      final results = await Future.wait([
        _loadStatistics(),
        _loadFlights(),
        _loadDisplayName(),
        _loadConnectivity(),
        _loadDistanceUnit(),
        _loadDateDisplayFormat(),
      ]);

      final statistics = results[0] as FlightStatistics;
      final flights = results[1] as List<Flight>;
      final displayName = results[2] as String;
      final hasInternet = results[3] as bool;
      final distanceUnit = results[4] as DistanceUnit;
      final dateDisplayFormat = results[5] as DateDisplayFormat;
      _allFlights = flights;

      emit(
        HomeTabSuccess(
          statistics: statistics.copyWithDistanceUnit(distanceUnit),
          flights: _sortedFlights(),
          sort: _sort,
          displayName: displayName,
          hasInternet: hasInternet,
          distanceUnit: distanceUnit,
          dateDisplayFormat: dateDisplayFormat,
        ),
      );
    } catch (e) {
      emit(HomeTabError(t.home.failedToLoadFlights));
    }
  }

  /// Load flight statistics
  Future<FlightStatistics> _loadStatistics() async {
    try {
      final totalFlights = await _repository.getTotalFlights();
      final totalDownloadedMaps = await _repository.getTotalDownloadedMaps();
      final totalMapSize = await _repository.getTotalMapSize();
      final totalDistanceKm = await _repository.getTotalFlightDistanceKm();

      return FlightStatistics(
        totalFlights: totalFlights,
        totalDownloadedMaps: totalDownloadedMaps,
        totalMapSize: totalMapSize,
        totalDistanceKm: totalDistanceKm,
      );
    } catch (e) {
      _logger.error('Error loading statistics: $e');
      return FlightStatistics.zero();
    }
  }

  /// Load flights for home list
  Future<List<Flight>> _loadFlights() async {
    try {
      final flights = await _repository.getAllFlights();
      final activeFlights = flights
          .where((flight) => flight.status != FlightStatus.completed)
          .toList();
      _logger.log(
        'Loaded ${flights.length} flights from database (${activeFlights.length} active)',
      );
      // Sort by createdAt descending (newest first)
      final sorted = [...activeFlights]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sorted;
    } catch (e) {
      _logger.error('Error loading flights: $e');
      return <Flight>[];
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    _logger.log('Refreshing home tab data...');
    final currentState = state;
    if (currentState is HomeTabSuccess) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      // Load data in parallel
      final results = await Future.wait([
        _loadStatistics(),
        _loadFlights(),
        _loadDisplayName(),
        _loadConnectivity(),
        _loadDistanceUnit(),
        _loadDateDisplayFormat(),
      ]);

      final statistics = results[0] as FlightStatistics;
      final flights = results[1] as List<Flight>;
      final displayName = results[2] as String;
      final hasInternet = results[3] as bool;
      final distanceUnit = results[4] as DistanceUnit;
      final dateDisplayFormat = results[5] as DateDisplayFormat;
      _allFlights = flights;

      _logger.log('Refresh completed: ${flights.length} flights loaded');
      emit(
        HomeTabSuccess(
          statistics: statistics.copyWithDistanceUnit(distanceUnit),
          flights: _sortedFlights(),
          sort: _sort,
          displayName: displayName,
          hasInternet: hasInternet,
          isRefreshing: false,
          distanceUnit: distanceUnit,
          dateDisplayFormat: dateDisplayFormat,
        ),
      );
    } catch (e) {
      _logger.error('Error during refresh: $e');
      if (currentState is HomeTabSuccess) {
        emit(
          HomeTabError(
            t.home.failedToLoadFlights,
            statistics: currentState.statistics,
            upcomingFlights: currentState.flights,
          ),
        );
      } else {
        emit(HomeTabError(t.home.failedToLoadFlights));
      }
    }
  }

  /// Retry loading data after error
  Future<void> retry() async {
    await _loadData();
  }

  /// Get current statistics
  FlightStatistics? get currentStatistics {
    final currentState = state;
    if (currentState is HomeTabSuccess) {
      return currentState.statistics;
    } else if (currentState is HomeTabError) {
      return currentState.statistics;
    }
    return null;
  }

  /// Check if data is currently loading
  bool get isLoading {
    return state is HomeTabLoading;
  }

  /// Check if data is currently refreshing
  bool get isRefreshing {
    final currentState = state;
    if (currentState is HomeTabSuccess) {
      return currentState.isRefreshing;
    }
    return false;
  }

  /// Check if there's an error
  bool get hasError {
    return state is HomeTabError;
  }

  /// Get error message if any
  String? get errorMessage {
    final currentState = state;
    if (currentState is HomeTabError) {
      return currentState.message;
    }
    return null;
  }

  Future<void> setSort(HomeFlightsSort sort) async {
    if (_sort == sort) return;
    _sort = sort;
    final currentState = state;
    if (currentState is! HomeTabSuccess) return;

    emit(currentState.copyWith(flights: _sortedFlights(), sort: _sort));
  }

  Future<bool> deleteFlight(String flightId) async {
    try {
      final ok = await _deleteFlightUseCase(flightId);
      if (!ok) return false;

      await refresh();
      return true;
    } catch (e) {
      _logger.error('Failed to delete flight $flightId: $e');
      return false;
    }
  }

  Future<bool> completeFlight({
    required String flightId,
    required bool deleteOfflineData,
  }) async {
    final useCase = _completeFlightUseCase;
    if (useCase == null) return false;
    try {
      final ok = await useCase(
        flightId: flightId,
        deleteOfflineData: deleteOfflineData,
      );
      if (!ok) return false;
      await refresh();
      return true;
    } catch (e) {
      _logger.error('Failed to complete flight $flightId: $e');
      return false;
    }
  }

  Future<String> _loadDisplayName() async {
    try {
      final profile = await _onboardingRepository.getProfile();
      return profile.displayName.trim();
    } catch (e) {
      _logger.error('Error loading profile display name: $e');
      return '';
    }
  }

  Future<bool> _loadConnectivity() async {
    try {
      return await _connectivityChecker.hasInternetConnectivity();
    } catch (e) {
      _logger.error('Error checking internet connectivity: $e');
      return true;
    }
  }

  Future<DistanceUnit> _loadDistanceUnit() async {
    try {
      return await _unitsRepository.getDistanceUnit();
    } catch (e) {
      _logger.error('Error loading distance unit: $e');
      return DistanceUnit.km;
    }
  }

  Future<DateDisplayFormat> _loadDateDisplayFormat() async {
    try {
      return await _unitsRepository.getDateDisplayFormat();
    } catch (e) {
      _logger.error('Error loading date display format: $e');
      return DateDisplayFormat.us;
    }
  }

  List<Flight> _sortedFlights() {
    final sorted = [..._allFlights];
    switch (_sort) {
      case HomeFlightsSort.mostRecent:
        // Dated upcoming flights first (soonest departure on top), then the
        // dateless/past ones by creation date as before.
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        DateTime? upcomingTravelDate(Flight flight) {
          final travelDate = flight.schedule?.travelDate;
          if (travelDate == null) return null;
          if (flight.status == FlightStatus.completed) return null;
          return travelDate.isBefore(today) ? null : travelDate;
        }
        sorted.sort((a, b) {
          final dateA = upcomingTravelDate(a);
          final dateB = upcomingTravelDate(b);
          if (dateA != null && dateB != null) return dateA.compareTo(dateB);
          if (dateA != null) return -1;
          if (dateB != null) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case HomeFlightsSort.longestDistance:
        sorted.sort(
          (a, b) => b.route.distanceInKm.compareTo(a.route.distanceInKm),
        );
        break;
      case HomeFlightsSort.alphabetical:
        sorted.sort((a, b) => a.routeName.compareTo(b.routeName));
        break;
    }
    return sorted;
  }
}
