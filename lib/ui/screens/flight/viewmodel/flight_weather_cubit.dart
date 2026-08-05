import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/flight_weather_store.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/entity/flight_weather.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:flymap/logger.dart';
import 'package:get_it/get_it.dart';

class FlightWeatherState extends Equatable {
  const FlightWeatherState({
    this.isLoading = false,
    this.weather,
    this.failed = false,
  });

  final bool isLoading;

  /// Live fetch result, or the last persisted forecast (see
  /// [FlightWeather.fetchedAt] for its age).
  final FlightWeather? weather;

  final bool failed;

  @override
  List<Object?> get props => [isLoading, weather, failed];
}

/// Forecast for a SAVED flight (hub row preview + weather screen share one
/// instance). Persistence-first: the last stored forecast shows instantly
/// (that's what airplane mode gets), then a fresh fetch replaces it when
/// allowed — same access rules as the create-flight step (no API call
/// without Pro access, none beyond the reliable horizon) — and every
/// successful fetch is stored back for the next offline open.
class FlightWeatherCubit extends Cubit<FlightWeatherState> {
  FlightWeatherCubit({
    required this.flight,
    FetchFlightWeatherUseCase? useCase,
    FlightWeatherStore? store,
    DateTime Function()? now,
  }) : _useCase =
           useCase ??
           (GetIt.I.isRegistered<FetchFlightWeatherUseCase>()
               ? GetIt.I.get<FetchFlightWeatherUseCase>()
               : null),
       _store =
           store ??
           (GetIt.I.isRegistered<FlightWeatherStore>()
               ? GetIt.I.get<FlightWeatherStore>()
               : null),
       _now = now ?? DateTime.now,
       super(const FlightWeatherState());

  static const _logger = Logger('FlightWeatherCubit');

  static const retryCooldown = Duration(minutes: 1);

  final Flight flight;
  final FetchFlightWeatherUseCase? _useCase;
  final FlightWeatherStore? _store;
  final DateTime Function() _now;
  bool _storeChecked = false;
  DateTime? _lastFailedAt;

  /// A date picked in-session for a dateless flight, overriding the flight's
  /// (missing) schedule until the flight record reloads with the persisted one.
  FlightSchedule? _scheduleOverride;
  FlightSchedule? get _schedule => _scheduleOverride ?? flight.schedule;

  bool get isBeyondHorizon =>
      FlightWeatherVerdictPolicy.isBeyondForecastHorizon(
        _schedule,
        now: _now(),
      );

  bool get isPast =>
      FlightWeatherVerdictPolicy.isInPast(_schedule, now: _now());

  /// Applies a date picked on the weather screen for a dateless flight, then
  /// force-fetches. The caller persists the schedule on the flight record.
  Future<void> applySchedule(
    FlightSchedule schedule, {
    required bool hasProAccess,
  }) async {
    _scheduleOverride = schedule;
    await fetchIfNeeded(hasProAccess: hasProAccess, force: true);
  }

  Future<void> fetchIfNeeded({
    required bool hasProAccess,
    bool force = false,
  }) async {
    if (!hasProAccess || state.isLoading) return;
    // No date -> the screen shows a "pick a date" prompt; skip the fetch
    // rather than produce a meaningless today's-weather estimate.
    if (_schedule == null) return;

    // Stored forecast first: instant content, and the only content there
    // is in airplane mode.
    if (!_storeChecked) {
      _storeChecked = true;
      final stored = await _store?.load(flight.id);
      if (isClosed) return;
      if (stored != null && state.weather == null) {
        emit(FlightWeatherState(weather: stored));
      }
    }

    final useCase = _useCase;
    if (useCase == null || isPast || isBeyondHorizon) return;
    final current = state.weather;
    final isFresh = current?.isFreshAt(_now()) ?? false;
    final failedAt = _lastFailedAt;
    final retryCoolingDown =
        failedAt != null && _now().difference(failedAt) < retryCooldown;
    if (!force && (isFresh || retryCoolingDown)) return;

    emit(FlightWeatherState(isLoading: true, weather: current));
    try {
      final weather = await useCase.call(
        route: flight.route,
        schedule: _schedule,
      );
      if (isClosed) return;
      _lastFailedAt = null;
      emit(FlightWeatherState(weather: weather));
      await _store?.save(flight.id, weather);
    } catch (e) {
      _logger.error('flight weather fetch failed: $e');
      if (isClosed) return;
      _lastFailedAt = _now();
      // Keep showing the stored forecast; only flag failure when there is
      // nothing at all to show.
      emit(FlightWeatherState(weather: current, failed: current == null));
    }
  }
}
