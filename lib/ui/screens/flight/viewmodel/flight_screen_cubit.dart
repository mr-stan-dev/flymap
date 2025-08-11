import 'dart:async';
import 'dart:io';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:flymap/data/gps_data_provider.dart';
import 'package:geolocator/geolocator.dart';

class FlightScreenCubit extends Cubit<FlightScreenState> {
  final _logger = Logger('FlightScreenCubit');
  final Flight flight;
  final FlightRepository _repository = GetIt.I.get();
  final GpsDataProvider _gpsProvider = GpsDataProvider();
  Timer? _gpsCheckTimer;

  FlightScreenCubit({required this.flight}) : super(FlightScreenLoading()) {
    load();
  }

  Future<void> load() async {
    await _gpsProvider.start(
      onUpdate: (status, {data}) {
        emit(
          FlightScreenLoaded(flight: flight, gpsStatus: status, gpsData: data),
        );
      },
    );
    _gpsCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkGpsStatus(),
    );
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

  Future<void> _checkGpsStatus() async {
    // Provider emits status updates continuously; nothing to do here for now
  }

  Future<void> requestLocationPermission() async {
    // Permissions are handled within provider on start
    await load();
  }

  void openLocationSettings() {
    Geolocator.openLocationSettings();
  }

  @override
  Future<void> close() {
    _gpsCheckTimer?.cancel();
    _gpsProvider.stop();
    return super.close();
  }
}
