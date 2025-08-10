import 'dart:async';
import 'dart:io';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flymap/logger.dart';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:get_it/get_it.dart';

class FlightScreenCubit extends Cubit<FlightScreenState> {
  final _logger = Logger('FlightScreenCubit');
  final Flight flight;
  final FlightRepository _repository = GetIt.I.get();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _gpsCheckTimer;

  FlightScreenCubit({required this.flight}) : super(FlightScreenLoading()) {
    load();
  }

  Future<void> load() async {
    _initializeGps();
  }

  Future<void> deleteFlight() async {
    emit(const FlightScreenLoading());
    try {
      // Delete associated map files from disk
      final mapFiles = flight.maps;
      for (final mf in mapFiles) {
        final file = File(mf.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete map records from DB
      await _repository.deleteMapsForFlight(flight.id);

      // Delete flight record from DB
      final ok = await _repository.deleteFlight(flight.id);
      if (!ok) {
        emit(FlightScreenError('Failed to delete flight', flight: flight));
        return;
      }

      emit(const FlightScreenDeleted('Flight deleted'));
    } catch (e) {
      emit(FlightScreenError('Error deleting flight: $e', flight: flight));
    }
  }

  Future<void> _initializeGps() async {
    // Check if GPS is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(FlightScreenLoaded(flight: flight, gpsStatus: GpsStatus.off));
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(
          FlightScreenLoaded(
            flight: flight,
            gpsStatus: GpsStatus.permissionsNotGranted,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(
        FlightScreenLoaded(
          flight: flight,
          gpsStatus: GpsStatus.permissionsNotGranted,
        ),
      );
      return;
    }

    // Start GPS tracking
    _startGpsTracking();
  }

  void _startGpsTracking() {
    emit(FlightScreenLoaded(flight: flight, gpsStatus: GpsStatus.searching));

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _handlePositionUpdate(position);
          },
          onError: (error) {
            emit(
              FlightScreenLoaded(
                flight: flight,
                gpsStatus: GpsStatus.weakSignal,
                gpsData: GpsData(
                  accuracy: 100.0,
                ), // High accuracy value indicates weak signal
              ),
            );
          },
        );

    // Set up periodic GPS status check
    _gpsCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkGpsStatus();
    });
  }

  void _handlePositionUpdate(Position position) {
    final accuracy = position.accuracy;
    emit(
      FlightScreenLoaded(
        flight: flight,
        gpsStatus: GpsStatus.gpsActive,
        gpsData: GpsData(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          speed: position.speed,
          course: position.heading,
          accuracy: accuracy,
        ),
      ),
    );
  }

  Future<void> _checkGpsStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(FlightScreenLoaded(flight: flight, gpsStatus: GpsStatus.off));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      emit(
        FlightScreenLoaded(
          flight: flight,
          gpsStatus: GpsStatus.permissionsNotGranted,
        ),
      );
      return;
    }
  }

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _initializeGps();
    } else {
      emit(
        FlightScreenLoaded(
          flight: flight,
          gpsStatus: GpsStatus.permissionsNotGranted,
        ),
      );
    }
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _gpsCheckTimer?.cancel();
    return super.close();
  }
}
