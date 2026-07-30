import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/gps_data_provider.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/viewmodel/geo_awareness_engine.dart';
import 'package:flymap/domain/usecase/complete_flight_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/domain/usecase/start_flight_use_case.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

class FlightScreenCubit extends Cubit<FlightScreenState> {
  final _logger = Logger('FlightScreenCubit');
  static const _gpsStaleThreshold = Duration(seconds: 20);
  final Flight flight;
  Flight _currentFlight;
  final FlightRepository? _flightRepository;
  final DeleteFlightUseCase _deleteFlightUseCase;
  final CompleteFlightUseCase _completeFlightUseCase;
  final StartFlightUseCase _startFlightUseCase;
  final GpsDataProvider _gpsProvider;
  final GeoAwarenessEngine _geoAwarenessEngine;
  final DateTime Function() _nowProvider;
  final Duration _gpsStaleThresholdOverride;
  final bool _enableGpsCheckTimer;
  Timer? _gpsCheckTimer;
  int _gpsUpdateTick = 0;
  DateTime? _lastGpsEventAt;
  bool _debugGpsOverrideActive = false;

  FlightScreenCubit({
    required this.flight,
    FlightRepository? flightRepository,
    DeleteFlightUseCase? deleteFlightUseCase,
    CompleteFlightUseCase? completeFlightUseCase,
    StartFlightUseCase? startFlightUseCase,
    GpsDataProvider? gpsProvider,
    GeoAwarenessEngine? geoAwarenessEngine,
    DateTime Function()? nowProvider,
    Duration gpsStaleThreshold = _gpsStaleThreshold,
    bool enableGpsCheckTimer = true,
  }) : _currentFlight = flight,
       _flightRepository =
           flightRepository ??
           (GetIt.I.isRegistered<FlightRepository>()
               ? GetIt.I.get<FlightRepository>()
               : null),
       _deleteFlightUseCase = deleteFlightUseCase ?? GetIt.I.get(),
       _completeFlightUseCase = completeFlightUseCase ?? GetIt.I.get(),
       _startFlightUseCase = startFlightUseCase ?? GetIt.I.get(),
       _gpsProvider = gpsProvider ?? GetIt.I.get(),
       _geoAwarenessEngine = geoAwarenessEngine ?? const GeoAwarenessEngine(),
       _nowProvider = nowProvider ?? DateTime.now,
       _gpsStaleThresholdOverride = gpsStaleThreshold,
       _enableGpsCheckTimer = enableGpsCheckTimer,
       super(FlightScreenLoading()) {
    _logger.log('flight routeInsights: ${flight.routeInsights}');
    load();
  }

  Future<void> load() async {
    await _startGpsListening();
  }

  /// Re-reads the flight from storage so screens pick up changes made from a
  /// pushed section screen (e.g. a date added or the flight unlocked on the
  /// weather screen), which persist to the repository but not to the in-memory
  /// snapshot this cubit holds. A no-op emit when nothing changed (the Loaded
  /// state is value-equal).
  Future<void> reload() async {
    final repo = _flightRepository;
    if (repo == null) return;
    final fresh = await repo.getFlightById(_currentFlight.id);
    if (fresh == null || isClosed) return;
    _currentFlight = fresh;
    final current = state;
    if (current is FlightScreenLoaded) {
      emit(current.copyWith(flight: fresh));
    }
  }

  Future<void> _startGpsListening() async {
    await _gpsProvider.stop();
    _gpsCheckTimer?.cancel();

    await _gpsProvider.start(
      onUpdate: (status, {data}) {
        if (_debugGpsOverrideActive) {
          return;
        }
        switch (status) {
          case GpsStatus.gpsActive:
          case GpsStatus.weakSignal:
          case GpsStatus.searching:
            _lastGpsEventAt = _nowProvider();
            break;
          case GpsStatus.off:
          case GpsStatus.permissionsNotGranted:
            _lastGpsEventAt = null;
            break;
        }
        _emitTelemetryUpdate(status: status, data: data);
      },
    );
    if (_enableGpsCheckTimer) {
      _gpsCheckTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _checkGpsStatus(),
      );
    }
  }

  Future<void> deleteFlight() async {
    emit(const FlightScreenLoading());
    try {
      final ok = await _deleteFlightUseCase(_currentFlight.id);
      if (!ok) {
        emit(
          FlightScreenError(t.home.failedDeleteFlight, flight: _currentFlight),
        );
        return;
      }

      emit(FlightScreenDeleted(t.flight.deleted));
    } catch (e) {
      emit(
        FlightScreenError(
          t.flight.deleteError(error: e.toString()),
          flight: _currentFlight,
        ),
      );
    }
  }

  Future<bool> checkInFlight() async {
    if (_currentFlight.status == FlightStatus.inProgress) {
      return true;
    }
    try {
      final ok = await _startFlightUseCase(flightId: _currentFlight.id);
      if (!ok) {
        return false;
      }

      _currentFlight = _currentFlight.copyWith(
        timestamp: _currentFlight.timestamp.copyWith(
          inProgressAt: DateTime.now(),
        ),
        status: FlightStatus.inProgress,
      );

      final currentState = state;
      if (currentState is FlightScreenLoaded) {
        emit(currentState.copyWith(flight: _currentFlight));
      } else {
        emit(
          FlightScreenLoaded(
            flight: _currentFlight,
            routeRegions: _currentFlight.info.routeRegions,
          ),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> completeFlight({required bool deleteOfflineData}) async {
    try {
      final ok = await _completeFlightUseCase(
        flightId: _currentFlight.id,
        deleteOfflineData: deleteOfflineData,
      );
      if (!ok) return false;

      final current = state;
      if (current is FlightScreenLoaded) {
        _currentFlight = current.flight.copyWith(
          maps: deleteOfflineData ? const [] : current.flight.maps,
          offlineContent: deleteOfflineData
              ? current.flight.offlineContent.copyWith(articles: const [])
              : current.flight.offlineContent,
          timestamp: FlightTimestamp(
            createdAt: current.flight.createdAt,
            completedAt: DateTime.now(),
          ),
          status: FlightStatus.completed,
        );
        emit(current.copyWith(flight: _currentFlight));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkGpsStatus() async {
    if (_debugGpsOverrideActive) return;

    final current = state;
    if (current is! FlightScreenLoaded) return;

    if (current.gps.status == GpsStatus.off ||
        current.gps.status == GpsStatus.permissionsNotGranted) {
      return;
    }

    final lastEventAt = _lastGpsEventAt;
    if (lastEventAt == null) {
      if (current.gps.status != GpsStatus.searching) {
        _emitTelemetryUpdate(status: GpsStatus.searching);
      }
      return;
    }

    final now = _nowProvider();
    final stale = now.difference(lastEventAt) > _gpsStaleThresholdOverride;
    if (stale && current.gps.status != GpsStatus.searching) {
      _emitTelemetryUpdate(status: GpsStatus.searching);
    }
  }

  Future<void> requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    await _startGpsListening();
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  void applyDebugGpsData(GpsData data, {bool resetGeoState = false}) {
    if (!kDebugMode) return;
    _debugGpsOverrideActive = true;
    _lastGpsEventAt = _nowProvider();
    _emitTelemetryUpdate(
      status: GpsStatus.gpsActive,
      data: data,
      resetGeoState: resetGeoState,
    );
  }

  @visibleForTesting
  Future<void> checkGpsStatusForTest() => _checkGpsStatus();

  void disableDebugGpsOverride() {
    if (!kDebugMode) return;
    _debugGpsOverrideActive = false;
  }

  void _emitTelemetryUpdate({
    required GpsStatus status,
    GpsData? data,
    bool resetGeoState = false,
  }) {
    final current = state is FlightScreenLoaded
        ? state as FlightScreenLoaded
        : null;
    final previousGeo = resetGeoState || current == null
        ? null
        : GeoAwarenessSnapshot(
            currentRegionIds: current.currentRegionIds,
            nextRegionId: current.nextRegionId,
            nextRegionEtaMinutes: current.nextRegionEtaMinutes,
            coveredDistanceKm: current.routeCoveredDistanceKm,
          );
    final geo = _geoAwarenessEngine.compute(
      route: _currentFlight.route,
      routeRegions: _currentFlight.info.routeRegions,
      gpsData: data,
      previous: previousGeo,
    );

    var lastVisitedRegionId = resetGeoState
        ? null
        : current?.lastVisitedRegionId;
    if (geo.currentRegionIds.isNotEmpty) {
      lastVisitedRegionId = geo.currentRegionIds.last;
    }
    final currentGps = current?.gps;
    final currentGpsData = currentGps?.data;
    final currentGpsLastFixAt = currentGps?.lastFixAt;
    final now = _nowProvider().toUtc();
    final resolvedGpsData = switch (status) {
      GpsStatus.gpsActive || GpsStatus.weakSignal => data,
      GpsStatus.searching => data ?? currentGpsData,
      GpsStatus.off || GpsStatus.permissionsNotGranted => null,
    };
    final resolvedGpsLastFixAt = switch (status) {
      GpsStatus.gpsActive ||
      GpsStatus.weakSignal => data != null ? now : currentGpsLastFixAt,
      GpsStatus.searching => currentGpsLastFixAt,
      GpsStatus.off || GpsStatus.permissionsNotGranted => null,
    };
    _gpsUpdateTick++;
    emit(
      FlightScreenLoaded(
        gps: FlightGpsState(
          status: status,
          data: resolvedGpsData,
          updateTick: _gpsUpdateTick,
          lastFixAt: resolvedGpsLastFixAt,
        ),
        flight: _currentFlight,
        routeRegions: _currentFlight.info.routeRegions,
        routeCoveredDistanceKm: geo.coveredDistanceKm,
        lastVisitedRegionId: lastVisitedRegionId,
        currentRegionIds: geo.currentRegionIds,
        nextRegionId: geo.nextRegionId,
        nextRegionEtaMinutes: geo.nextRegionEtaMinutes,
      ),
    );
  }

  @override
  Future<void> close() {
    _gpsCheckTimer?.cancel();
    _gpsProvider.stop();
    return super.close();
  }
}
