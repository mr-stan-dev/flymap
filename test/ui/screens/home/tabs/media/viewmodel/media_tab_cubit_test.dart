import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_insights.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/media/viewmodel/media_tab_state.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;

  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });
  tearDownAll(() => PathProviderPlatform.instance = originalPathProvider);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'builds folders by flight and keeps no-flight captures separate',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'sky-camera-media-cubit',
      );
      addTearDown(() => tempDir.delete(recursive: true));

      final database = await databaseFactoryIo.openDatabase(
        p.join(tempDir.path, 'media.db'),
      );
      addTearDown(database.close);

      final repository = SkyCameraMediaRepository(
        database: AppDatabase.test(database: database),
      );

      await repository.addCapture(
        _item(
          id: 'capture-1',
          capturedAt: DateTime(2026, 6, 30, 10, 0),
          flightId: 'flight-1',
          originCode: 'BRS',
          destinationCode: 'BER',
        ),
      );
      await repository.addCapture(
        _item(
          id: 'capture-2',
          capturedAt: DateTime(2026, 6, 30, 11, 0),
          flightId: 'flight-1',
          originCode: 'BRS',
          destinationCode: 'BER',
        ),
      );
      await repository.addCapture(
        _item(id: 'capture-3', capturedAt: DateTime(2026, 6, 30, 12, 0)),
      );

      final cubit = MediaTabCubit(
        repository: repository,
        flightRepository: _FakeFlightRepository(
          flights: [
            _flight(
              id: 'flight-1',
              departureCode: 'BRS',
              departureCity: 'Bristol',
              arrivalCode: 'BER',
              arrivalCity: 'Berlin',
            ),
          ],
        ),
        metricUnitsRepository: MetricUnitsRepository(),
      );
      addTearDown(cubit.close);

      await cubit.load();

      final state = cubit.state;
      expect(state, isA<MediaTabLoaded>());
      final loaded = state as MediaTabLoaded;
      expect(loaded.folders, hasLength(2));
      expect(loaded.folders.first.title, 'No flight context');
      expect(loaded.folders.first.captures, hasLength(1));
      expect(loaded.folders[1].title, 'BRS - BER');
      expect(loaded.folders[1].subtitle, 'Bristol - Berlin');
      expect(loaded.folders[1].captures, hasLength(2));
    },
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

SkyCameraMediaItem _item({
  required String id,
  required DateTime capturedAt,
  String? flightId,
  String originCode = '',
  String destinationCode = '',
}) {
  return SkyCameraMediaItem(
    id: id,
    capturedAt: capturedAt,
    mediaType: SkyCameraMediaType.photo,
    sourcePath: '/tmp/$id.jpg',
    flightId: flightId,
    snapshot: SkyCameraOverlaySnapshot(
      timestamp: capturedAt,
      routeLabel: originCode.isNotEmpty && destinationCode.isNotEmpty
          ? '$originCode -> $destinationCode'
          : 'Placeholder',
      originCode: originCode,
      destinationCode: destinationCode,
      originCountryCode: 'GB',
      destinationCountryCode: 'ES',
      contextLabel: 'Context',
      mapStatePlaceholder: 'Map',
      hasLiveLocation: false,
      latitude: null,
      longitude: null,
      headingDegrees: null,
      altitudeMeters: null,
      speedMetersPerSecond: null,
    ),
    renditions: [
      SkyCameraMediaRendition(
        id: 'default',
        skinId: 'flymap_default_v1',
        mediaType: SkyCameraMediaType.photo,
        path: '/tmp/$id-overlay.png',
        previewImagePath: '/tmp/$id-overlay.png',
      ),
    ],
    trackPoints: const [],
    previewImagePath: '/tmp/$id-overlay.png',
    selectedRenditionId: 'default',
  );
}

class _FakeFlightRepository implements FlightRepository {
  @override
  Future<bool> updateFlightAccessTier({
    required String flightId,
    required String accessTier,
  }) async => true;

  _FakeFlightRepository({required this.flights});

  final List<Flight> flights;

  @override
  Future<List<Flight>> getAllFlights() async => flights;

  @override
  Future<Flight?> getFlightById(String flightId) async {
    for (final flight in flights) {
      if (flight.id == flightId) return flight;
    }
    return null;
  }

  @override
  Future<String> insertFlight(Flight flight) {
    throw UnimplementedError();
  }

  @override
  Future<String> saveOrUpdateFlight(Flight flight) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateFlightInfo({
    required String flightId,
    required FlightInfo info,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateFlightStatus({
    required String flightId,
    required FlightStatus status,
    DateTime? completedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<int> getTotalDownloadedMaps() {
    throw UnimplementedError();
  }

  @override
  Future<double> getTotalFlightDistanceKm() {
    throw UnimplementedError();
  }

  @override
  Future<int> getTotalFlights() {
    throw UnimplementedError();
  }

  @override
  Future<int> getTotalMapSize() {
    throw UnimplementedError();
  }
}

Flight _flight({
  required String id,
  required String departureCode,
  required String departureCity,
  required String arrivalCode,
  required String arrivalCity,
}) {
  return Flight(
    id: id,
    route: FlightRoute(
      departure: Airport(
        name: departureCity,
        city: departureCity,
        countryCode: 'GB',
        latLon: const LatLng(51.0, -2.0),
        iataCode: departureCode,
        icaoCode: '',
        wikipediaUrl: '',
      ),
      arrival: Airport(
        name: arrivalCity,
        city: arrivalCity,
        countryCode: 'DE',
        latLon: const LatLng(52.0, 13.0),
        iataCode: arrivalCode,
        icaoCode: '',
        wikipediaUrl: '',
      ),
      waypoints: const [],
      corridor: const [],
    ),
    routeInsights: FlightRouteInsights.empty,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 6, 30, 9, 0)),
  );
}
