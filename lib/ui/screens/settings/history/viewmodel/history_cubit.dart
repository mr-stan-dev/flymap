import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/domain/usecase/complete_flight_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/restore_flight_use_case.dart';

import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required FlightRepository repository,
    required MetricUnitsRepository unitsRepository,
    required DeleteFlightUseCase deleteFlightUseCase,
    required CompleteFlightUseCase completeFlightUseCase,
    required RestoreFlightUseCase restoreFlightUseCase,
  }) : _repository = repository,
       _unitsRepository = unitsRepository,
       _deleteFlightUseCase = deleteFlightUseCase,
       _completeFlightUseCase = completeFlightUseCase,
       _restoreFlightUseCase = restoreFlightUseCase,
       super(const HistoryLoading()) {
    load();
  }

  final FlightRepository _repository;
  final MetricUnitsRepository _unitsRepository;
  final DeleteFlightUseCase _deleteFlightUseCase;
  final CompleteFlightUseCase _completeFlightUseCase;
  final RestoreFlightUseCase _restoreFlightUseCase;
  final Logger _logger = const Logger('HistoryCubit');

  HistorySort _sort = HistorySort.date;
  List<HistoryItem> _allItems = const [];

  Future<void> load() async {
    emit(const HistoryLoading());
    try {
      final flights = await _repository.getAllFlights();
      final distanceUnit = await _loadDistanceUnit();
      final dateDisplayFormat = await _loadDateDisplayFormat();
      _allItems = flights.map((f) => HistoryItem(flight: f)).toList();
      emit(
        HistorySuccess(
          items: _sortedItems(),
          sort: _sort,
          totalFlights: flights.length,
          totalDistanceKm: _totalDistanceKm(flights),
          distanceUnit: distanceUnit,
          dateDisplayFormat: dateDisplayFormat,
        ),
      );
    } catch (e) {
      _logger.error('Failed to load history: $e');
      emit(HistoryError(t.settings.historyLoadError));
    }
  }

  Future<void> setSort(HistorySort sort) async {
    if (_sort == sort) return;
    _sort = sort;
    final current = state;
    if (current is! HistorySuccess) return;
    emit(current.copyWith(items: _sortedItems(), sort: _sort));
  }

  Future<bool> deleteFlight(String flightId) async {
    try {
      final ok = await _deleteFlightUseCase(flightId);
      if (!ok) return false;
      await load();
      return true;
    } catch (e) {
      _logger.error('Failed to delete flight in history: $e');
      return false;
    }
  }

  Future<bool> completeFlight({
    required String flightId,
    required bool deleteOfflineData,
  }) async {
    try {
      final ok = await _completeFlightUseCase(
        flightId: flightId,
        deleteOfflineData: deleteOfflineData,
      );
      if (!ok) return false;
      await load();
      return true;
    } catch (e) {
      _logger.error('Failed to complete flight in history: $e');
      return false;
    }
  }

  Future<bool> restoreFlight(String flightId) async {
    try {
      final ok = await _restoreFlightUseCase(flightId: flightId);
      if (!ok) return false;
      await load();
      return true;
    } catch (e) {
      _logger.error('Failed to restore flight from history: $e');
      return false;
    }
  }

  double _totalDistanceKm(List<Flight> flights) {
    return flights.fold<double>(0, (sum, f) => sum + f.route.distanceInKm);
  }

  List<HistoryItem> _sortedItems() {
    final sorted = [..._allItems];
    switch (_sort) {
      case HistorySort.name:
        sorted.sort(
          (a, b) => a.flight.routeName.toLowerCase().compareTo(
            b.flight.routeName.toLowerCase(),
          ),
        );
        break;
      case HistorySort.distance:
        sorted.sort(
          (a, b) => b.flight.route.distanceInKm.compareTo(
            a.flight.route.distanceInKm,
          ),
        );
        break;
      case HistorySort.date:
        sorted.sort((a, b) => b.flight.createdAt.compareTo(a.flight.createdAt));
        break;
    }
    return sorted;
  }

  Future<DistanceUnit> _loadDistanceUnit() async {
    try {
      return await _unitsRepository.getDistanceUnit();
    } catch (_) {
      return DistanceUnit.km;
    }
  }

  Future<DateDisplayFormat> _loadDateDisplayFormat() async {
    try {
      return await _unitsRepository.getDateDisplayFormat();
    } catch (_) {
      return DateDisplayFormat.us;
    }
  }
}
