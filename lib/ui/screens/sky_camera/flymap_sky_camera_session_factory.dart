import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_analytics_observer.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_export_service.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_overlay_snapshot_source.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_share_service.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraSession {
  const FlymapSkyCameraSession({
    required this.driver,
    required this.snapshotSource,
    required this.exportService,
    required this.shareService,
    required this.observer,
  });

  final SkyCameraDriver driver;
  final SkyCameraOverlaySnapshotSource snapshotSource;
  final SkyCameraExportService exportService;
  final SkyCameraShareService shareService;
  final SkyCameraObserver observer;
}

class FlymapSkyCameraPlaceholderCopy {
  const FlymapSkyCameraPlaceholderCopy({
    required this.routeLabel,
    required this.originCode,
    required this.destinationCode,
    required this.originCountryCode,
    required this.destinationCountryCode,
    required this.contextLabel,
    required this.mapPlaceholder,
  });

  final String routeLabel;
  final String originCode;
  final String destinationCode;
  final String originCountryCode;
  final String destinationCountryCode;
  final String contextLabel;
  final String mapPlaceholder;
}

class FlymapSkyCameraSessionFactory {
  const FlymapSkyCameraSessionFactory({
    required this.exportService,
    required this.shareService,
    required this.analytics,
    required this.flightRepository,
    required this.locationService,
  });

  final FlymapSkyCameraExportService exportService;
  final FlymapSkyCameraShareService shareService;
  final AppAnalytics analytics;
  final FlightRepository flightRepository;
  final AppLocationService locationService;

  FlymapSkyCameraSession create({
    required FlymapSkyCameraPlaceholderCopy placeholderCopy,
  }) {
    return _create(
      placeholderCopy: placeholderCopy,
      sessionExportService: exportService,
    );
  }

  FlymapSkyCameraSession createForFlight({
    required FlymapSkyCameraPlaceholderCopy placeholderCopy,
    required String flightId,
  }) {
    return _create(
      placeholderCopy: placeholderCopy,
      sessionExportService: exportService.scopedToFlight(flightId),
    );
  }

  FlymapSkyCameraSession _create({
    required FlymapSkyCameraPlaceholderCopy placeholderCopy,
    required SkyCameraExportService sessionExportService,
  }) {
    return FlymapSkyCameraSession(
      driver: DeviceSkyCameraDriver(),
      snapshotSource: FlymapSkyCameraOverlaySnapshotSource(
        builder: FlymapSkyCameraOverlaySnapshotBuilder(
          placeholderCopy: placeholderCopy,
        ),
        locationService: locationService,
      ),
      exportService: sessionExportService,
      shareService: shareService,
      observer: FlymapSkyCameraAnalyticsObserver(
        analytics: analytics,
        flightRepository: flightRepository,
      ),
    );
  }
}
