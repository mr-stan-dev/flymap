import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/usecase/delete_flight_use_case.dart';
import 'package:get_it/get_it.dart';

/// Cubit for managing home tab state
class HomeTabCubit extends Cubit<HomeTabState> {
  final _logger = Logger('HomeTabCubit');
  HomeFlightsSort _sort = HomeFlightsSort.mostRecent;
  List<Flight> _allFlights = const [];

  HomeTabCubit() : super(const HomeTabLoading()) {
    _repository = GetIt.I<FlightRepository>();
    _deleteFlightUseCase = GetIt.I<DeleteFlightUseCase>();
    _loadData();
  }

  late final FlightRepository _repository;
  late final DeleteFlightUseCase _deleteFlightUseCase;

  /// Load all data for home tab
  Future<void> _loadData() async {
    try {
      emit(const HomeTabLoading());

      // Load data in parallel
      final results = await Future.wait([_loadStatistics(), _loadFlights()]);

      final statistics = results[0] as FlightStatistics;
      final flights = results[1] as List<Flight>;
      _allFlights = flights;

      emit(
        HomeTabSuccess(
          statistics: statistics,
          flights: _sortedFlights(),
          sort: _sort,
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

      return FlightStatistics(
        totalFlights: totalFlights,
        totalDownloadedMaps: totalDownloadedMaps,
        totalMapSize: totalMapSize,
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
      _logger.log('Loaded ${flights.length} flights from database');
      // Sort by createdAt descending (newest first)
      final sorted = [...flights]
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
      final results = await Future.wait([_loadStatistics(), _loadFlights()]);

      final statistics = results[0] as FlightStatistics;
      final flights = results[1] as List<Flight>;
      _allFlights = flights;

      _logger.log('Refresh completed: ${flights.length} flights loaded');
      emit(
        HomeTabSuccess(
          statistics: statistics,
          flights: _sortedFlights(),
          sort: _sort,
          isRefreshing: false,
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

  List<Flight> _sortedFlights() {
    final sorted = [..._allFlights];
    switch (_sort) {
      case HomeFlightsSort.mostRecent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
