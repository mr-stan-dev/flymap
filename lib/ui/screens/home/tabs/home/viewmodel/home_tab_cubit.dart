import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:get_it/get_it.dart';

/// Cubit for managing home tab state
class HomeTabCubit extends Cubit<HomeTabState> {
  final _logger = Logger('HomeTabCubit');

  HomeTabCubit() : super(const HomeTabLoading()) {
    _repository = GetIt.I<FlightRepository>();
    _loadData();
  }

  late final FlightRepository _repository;

  /// Load all data for home tab
  Future<void> _loadData() async {
    try {
      emit(const HomeTabLoading());

      // Load data in parallel
      final results = await Future.wait([_loadStatistics(), _loadFlights()]);

      final statistics = results[0] as FlightStatistics;
      final flights = results[1] as List<Flight>;

      emit(HomeTabSuccess(statistics: statistics, flights: flights));
    } catch (e) {
      emit(HomeTabError('Failed to load data: $e'));
    }
  }

  /// Load flight statistics
  Future<FlightStatistics> _loadStatistics() async {
    try {
      final totalFlights = await _repository.getTotalFlights();
      final totalDownloadedMaps = await _repository.getTotalDownloadedMaps();
      final totalMapSize = await _repository.getTotalMapSize();
      print('total flights: $totalFlights');

      return FlightStatistics(
        totalFlights: totalFlights,
        totalDownloadedMaps: totalDownloadedMaps,
        totalMapSize: totalMapSize,
      );
    } catch (e) {
      print('load statistics error: $e');
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

      _logger.log('Refresh completed: ${flights.length} flights loaded');
      emit(
        HomeTabSuccess(
          statistics: statistics,
          flights: flights,
          isRefreshing: false,
        ),
      );
    } catch (e) {
      _logger.error('Error during refresh: $e');
      if (currentState is HomeTabSuccess) {
        emit(
          HomeTabError(
            'Failed to refresh data: $e',
            statistics: currentState.statistics,
            upcomingFlights: currentState.flights,
          ),
        );
      } else {
        emit(HomeTabError('Failed to refresh data: $e'));
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
}
