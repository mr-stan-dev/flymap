import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraAnalyticsObserver implements SkyCameraObserver {
  FlymapSkyCameraAnalyticsObserver({
    required this.analytics,
    required this.flightRepository,
  });

  final AppAnalytics analytics;
  final FlightRepository flightRepository;

  late final Future<bool> _hasActiveFlightContext = _loadFlightContext();

  @override
  Future<void> onOpened({required SkyCameraOverlaySnapshot snapshot}) async {
    await analytics.log(
      SkyCameraOpenedEvent(
        hasActiveFlightContext: await _hasActiveFlightContext,
        hasLiveLocation: snapshot.hasLiveLocation,
      ),
    );
  }

  @override
  Future<void> onPhotoCaptured({
    required SkyCameraOverlaySnapshot snapshot,
  }) async {
    await analytics.log(
      SkyPhotoCaptureEvent(
        hasActiveFlightContext: await _hasActiveFlightContext,
        hasLiveLocation: snapshot.hasLiveLocation,
      ),
    );
  }

  @override
  Future<void> onVideoCaptured({
    required SkyCameraOverlaySnapshot snapshot,
    required Duration duration,
  }) async {
    await analytics.log(
      SkyVideoCaptureEvent(
        hasActiveFlightContext: await _hasActiveFlightContext,
        hasLiveLocation: snapshot.hasLiveLocation,
        durationSeconds: duration.inSeconds,
      ),
    );
  }

  Future<bool> _loadFlightContext() async {
    final flights = await flightRepository.getAllFlights();
    return flights.any((flight) => flight.status == FlightStatus.inProgress);
  }
}
