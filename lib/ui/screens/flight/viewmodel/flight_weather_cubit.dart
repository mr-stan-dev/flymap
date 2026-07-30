import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
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
  final FlightWeather? weather;
  final bool failed;

  @override
  List<Object?> get props => [isLoading, weather, failed];
}

/// Forecast for a SAVED flight (hub row preview + weather screen share one
/// instance). Same access rules as the create-flight step: no API call
/// without Pro access, none beyond the reliable horizon; fetched once per
/// flight-screen visit unless forced.
class FlightWeatherCubit extends Cubit<FlightWeatherState> {
  FlightWeatherCubit({required this.flight, FetchFlightWeatherUseCase? useCase})
    : _useCase =
          useCase ??
          (GetIt.I.isRegistered<FetchFlightWeatherUseCase>()
              ? GetIt.I.get<FetchFlightWeatherUseCase>()
              : null),
      super(const FlightWeatherState());

  static const _logger = Logger('FlightWeatherCubit');

  final Flight flight;
  final FetchFlightWeatherUseCase? _useCase;

  bool get isBeyondHorizon => FlightWeatherVerdictPolicy.isBeyondForecastHorizon(
    flight.schedule,
    now: DateTime.now(),
  );

  Future<void> fetchIfNeeded({required bool hasProAccess, bool force = false}) async {
    final useCase = _useCase;
    if (useCase == null || !hasProAccess || isBeyondHorizon) return;
    if (state.isLoading) return;
    if (!force && (state.weather != null || state.failed)) return;

    emit(const FlightWeatherState(isLoading: true));
    try {
      final weather = await useCase.call(
        route: flight.route,
        schedule: flight.schedule,
      );
      if (isClosed) return;
      emit(FlightWeatherState(weather: weather));
    } catch (e) {
      _logger.error('flight weather fetch failed: $e');
      if (isClosed) return;
      emit(const FlightWeatherState(failed: true));
    }
  }
}
