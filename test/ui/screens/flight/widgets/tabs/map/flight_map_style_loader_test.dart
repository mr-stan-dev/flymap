import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:flymap/data/tiles_downloader/mbtiles_validator.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_map.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_metrics.dart';
import 'package:flymap/domain/entity/flight_timestamp.dart';
import 'package:flymap/domain/entity/offline_map_style.dart';
import 'package:flymap/domain/entity/flight_waypoint.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_style_loader.dart';
import 'package:latlong2/latlong.dart';

void main() {
  late Directory tempDir;
  late _FakeMapAssetCacheService cacheService;
  late _FakeCrashlytics crashlytics;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('flymap-style-loader-test');
    cacheService = _FakeMapAssetCacheService();
    crashlytics = _FakeCrashlytics();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('loads liberty asset for offline map style', () async {
    final file = await _createMbtilesFile(tempDir, 'route.mbtiles');
    String? requestedAssetPath;
    final loader = FlightMapStyleLoader(
      logger: const Logger('test'),
      styleMapper: FlightMapStyleMapper(),
      mapAssetCacheService: cacheService,
      crashlytics: crashlytics,
      cacheDirectoryProvider: () async => tempDir,
      assetStyleLoader: (assetPath) async {
        requestedAssetPath = assetPath;
        return _minimalStyleJson;
      },
      mbtilesValidator: (_, __) async => MbtilesValidationResult.valid(),
    );

    final result = await loader.load(
      _buildFlight(file.path),
      style: OfflineMapStyle.liberty,
    );

    expect(result.isSuccess, isTrue);
    expect(requestedAssetPath, 'assets/styles/openfreemap_offline_style.json');
    expect(cacheService.ensureReadyCalled, isTrue);
    expect(result.styleString, contains('mbtiles://${file.absolute.path}'));
  });

  test('loads fiord asset for offline map style', () async {
    final file = await _createMbtilesFile(tempDir, 'route.mbtiles');
    String? requestedAssetPath;
    final loader = FlightMapStyleLoader(
      logger: const Logger('test'),
      styleMapper: FlightMapStyleMapper(),
      mapAssetCacheService: cacheService,
      crashlytics: crashlytics,
      cacheDirectoryProvider: () async => tempDir,
      assetStyleLoader: (assetPath) async {
        requestedAssetPath = assetPath;
        return _minimalStyleJson;
      },
      mbtilesValidator: (_, __) async => MbtilesValidationResult.valid(),
    );

    final result = await loader.load(
      _buildFlight(file.path),
      style: OfflineMapStyle.fiord,
    );

    expect(result.isSuccess, isTrue);
    expect(
      requestedAssetPath,
      'assets/styles/openfreemap_offline_fiord_style.json',
    );
  });

  test('returns missing error when resolved mbtiles file is absent', () async {
    final loader = FlightMapStyleLoader(
      logger: const Logger('test'),
      styleMapper: FlightMapStyleMapper(),
      mapAssetCacheService: cacheService,
      crashlytics: crashlytics,
      cacheDirectoryProvider: () async => tempDir,
      assetStyleLoader: (_) async => _minimalStyleJson,
      mbtilesValidator: (_, __) async => MbtilesValidationResult.valid(),
    );

    final result = await loader.load(
      _buildFlight('/downloads/missing.mbtiles'),
      style: OfflineMapStyle.liberty,
    );

    expect(result.isSuccess, isFalse);
    expect(result.errorMessage, isNotEmpty);
  });
}

const _minimalStyleJson =
    '{"version":8,"sources":{"openmaptiles":{"type":"vector","url":"https://tiles.openfreemap.org/planet"}},"layers":[]}';

Future<File> _createMbtilesFile(Directory tempDir, String fileName) async {
  final mbtilesDir = Directory('${tempDir.path}/mbtiles');
  await mbtilesDir.create(recursive: true);
  final file = File('${mbtilesDir.path}/$fileName');
  await file.writeAsBytes(const [1, 2, 3], flush: true);
  return file;
}

Flight _buildFlight(String storedPath) {
  const departure = Airport(
    name: 'London Heathrow',
    city: 'London',
    countryCode: 'GB',
    latLon: LatLng(51.47, -0.45),
    iataCode: 'LHR',
    icaoCode: 'EGLL',
    wikipediaUrl: '',
  );
  const arrival = Airport(
    name: 'Munich Airport',
    city: 'Munich',
    countryCode: 'DE',
    latLon: LatLng(48.35, 11.79),
    iataCode: 'MUC',
    icaoCode: 'EDDM',
    wikipediaUrl: '',
  );
  const route = FlightRoute(
    departure: departure,
    arrival: arrival,
    waypoints: [
      FlightWaypoint(latLon: LatLng(51.47, -0.45)),
      FlightWaypoint(latLon: LatLng(48.35, 11.79)),
    ],
    corridor: [
      LatLng(51.47, -0.45),
      LatLng(48.35, -0.45),
      LatLng(48.35, 11.79),
    ],
    metrics: FlightRouteMetrics(
      greatCircleDistanceKm: 1487.5,
      cruiseMinutes: 105,
    ),
  );

  return Flight(
    id: 'flight-1',
    route: route,
    maps: [
      FlightMap(
        layer: 'ofm_vector',
        sizeBytes: 1024,
        downloadedAt: DateTime(2026, 1, 1),
        filePath: storedPath,
      ),
    ],
    routeInsights: FlightInfo.empty.routeInsights,
    offlineContent: FlightInfo.empty.offlineContent,
    timestamp: FlightTimestamp(createdAt: DateTime(2026, 1, 1)),
  );
}

class _FakeMapAssetCacheService extends MapAssetCacheService {
  bool ensureReadyCalled = false;

  @override
  void ensureReadyInBackground() {
    ensureReadyCalled = true;
  }
}

class _FakeCrashlytics implements AppCrashlytics {
  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {}

  @override
  Future<void> recordFlutterError(details) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}

  @override
  Future<void> setContext({
    String? screen,
    int? routeLengthKm,
    String? mapDetail,
    String? flightNumber,
    int? articlesSelectedCount,
    String? downloadStage,
  }) async {}
}
