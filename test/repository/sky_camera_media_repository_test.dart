import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory defaultDocumentsDir;

  setUpAll(() async {
    originalPathProvider = PathProviderPlatform.instance;
    defaultDocumentsDir = await Directory.systemTemp.createTemp(
      'sky-camera-default-docs',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      defaultDocumentsDir.path,
    );
  });

  tearDownAll(() async {
    PathProviderPlatform.instance = originalPathProvider;
    if (await defaultDocumentsDir.exists()) {
      await defaultDocumentsDir.delete(recursive: true);
    }
  });

  test('persists media items and loads them newest first', () async {
    final repository = await _buildRepository('persist');

    await repository.addCapture(
      _item(
        id: 'older',
        capturedAt: DateTime(2026, 6, 30, 10, 0),
        originCode: 'BRS',
        destinationCode: 'BER',
      ),
    );
    await repository.addCapture(
      _item(
        id: 'newer',
        capturedAt: DateTime(2026, 6, 30, 11, 0),
        renditionPath: '/tmp/newer_overlay.png',
      ),
    );

    final captures = await repository.getCaptures();
    final selectedCaptures = await repository.getCapturesByIds([
      'older',
      'missing',
      'newer',
    ]);

    expect(captures.map((capture) => capture.id), ['newer', 'older']);
    expect(selectedCaptures.map((capture) => capture.id), ['older', 'newer']);
    expect(captures[1].routeLabel, 'BRS - BER');
    expect(captures.first.galleryImagePath, '/tmp/newer_overlay.png');
  });

  test(
    'persists outside temperature in snapshot and top-level metadata',
    () async {
      final repository = await _buildRepository('outside-temperature');

      await repository.addCapture(
        _item(
          id: 'temp',
          capturedAt: DateTime(2026, 6, 30, 10, 0),
          outsideTemperatureCelsius: -42.3,
        ),
      );

      final captures = await repository.getCaptures();

      expect(captures.single.outsideTemperatureCelsius, -42.3);
      expect(captures.single.snapshot.outsideTemperatureCelsius, -42.3);
    },
  );

  test('derives grid key and geohash for located media items', () async {
    final repository = await _buildRepository('spatial-keys');

    await repository.addCapture(
      _item(
        id: 'located',
        capturedAt: DateTime(2026, 6, 30, 10, 0),
        latitude: 51.5072,
        longitude: -0.1276,
      ),
    );

    final captures = await repository.getCaptures();

    expect(captures.single.gridKey, 'z6/31/21');
    expect(captures.single.geohash, 'gcpvj0');
  });

  test(
    'keeps items without location and excludes them from viewport results',
    () async {
      final repository = await _buildRepository('no-location');

      await repository.addCapture(
        _item(id: 'no-location', capturedAt: DateTime(2026, 6, 30, 10, 0)),
      );

      final captures = await repository.getCaptures();
      final visible = await repository.getCapturesInBounds(
        LatLngBounds(
          southwest: const LatLng(49.0, -1.0),
          northeast: const LatLng(53.0, 1.0),
        ),
      );

      expect(captures.single.gridKey, isNull);
      expect(captures.single.geohash, isNull);
      expect(visible, isEmpty);
    },
  );

  test('returns only items inside bounds sorted newest first', () async {
    final repository = await _buildRepository('viewport');

    await repository.addCapture(
      _item(
        id: 'inside-older',
        capturedAt: DateTime(2026, 6, 30, 9, 0),
        latitude: 51.5,
        longitude: -0.12,
      ),
    );
    await repository.addCapture(
      _item(
        id: 'inside-newer',
        capturedAt: DateTime(2026, 6, 30, 12, 0),
        latitude: 52.0,
        longitude: 0.1,
      ),
    );
    await repository.addCapture(
      _item(
        id: 'outside',
        capturedAt: DateTime(2026, 6, 30, 13, 0),
        latitude: 40.7,
        longitude: -74.0,
      ),
    );

    final visible = await repository.getCapturesInBounds(
      LatLngBounds(
        southwest: const LatLng(49.0, -2.0),
        northeast: const LatLng(53.0, 2.0),
      ),
    );

    expect(visible.map((capture) => capture.id), [
      'inside-newer',
      'inside-older',
    ]);
  });

  test('supports antimeridian-crossing viewport queries', () async {
    final repository = await _buildRepository('antimeridian');

    await repository.addCapture(
      _item(
        id: 'east-side',
        capturedAt: DateTime(2026, 6, 30, 10, 0),
        latitude: 0.5,
        longitude: 179.4,
      ),
    );
    await repository.addCapture(
      _item(
        id: 'west-side',
        capturedAt: DateTime(2026, 6, 30, 11, 0),
        latitude: -0.5,
        longitude: -179.2,
      ),
    );
    await repository.addCapture(
      _item(
        id: 'far-away',
        capturedAt: DateTime(2026, 6, 30, 12, 0),
        latitude: 0.0,
        longitude: -120.0,
      ),
    );

    final visible = await repository.getCapturesInBounds(
      LatLngBounds(
        southwest: const LatLng(-5.0, 170.0),
        northeast: const LatLng(5.0, -170.0),
      ),
    );

    expect(visible.map((capture) => capture.id), ['west-side', 'east-side']);
  });

  test('loads media items for one flight only', () async {
    final repository = await _buildRepository('flight-filter');

    await repository.addCapture(
      _item(
        id: 'flight-a-1',
        capturedAt: DateTime(2026, 6, 30, 9, 0),
        flightId: 'flight-a',
      ),
    );
    await repository.addCapture(
      _item(
        id: 'flight-b-1',
        capturedAt: DateTime(2026, 6, 30, 10, 0),
        flightId: 'flight-b',
      ),
    );
    await repository.addCapture(
      _item(
        id: 'flight-a-2',
        capturedAt: DateTime(2026, 6, 30, 11, 0),
        flightId: 'flight-a',
      ),
    );

    final captures = await repository.getCapturesForFlight('flight-a');

    expect(captures.map((capture) => capture.id), ['flight-a-2', 'flight-a-1']);
  });

  test('deletes media records and removes stored files', () async {
    final tempDir = await Directory.systemTemp.createTemp('sky-camera-delete');
    addTearDown(() => tempDir.delete(recursive: true));

    final database = await databaseFactoryIo.openDatabase(
      p.join(tempDir.path, 'media.db'),
    );
    addTearDown(database.close);

    final repository = SkyCameraMediaRepository(
      database: AppDatabase.test(database: database),
    );

    final original = File(p.join(tempDir.path, 'original.jpg'));
    final overlay = File(p.join(tempDir.path, 'overlay.png'));
    final alternateOverlay = File(p.join(tempDir.path, 'overlay-alt.png'));
    await original.writeAsBytes([1, 2, 3]);
    await overlay.writeAsBytes([4, 5, 6]);
    await alternateOverlay.writeAsBytes([7, 8, 9]);

    await repository.addCapture(
      _item(
        id: 'delete-me',
        capturedAt: DateTime(2026, 6, 30, 12, 0),
        sourcePath: original.path,
        renditionPath: overlay.path,
        extraRenditions: [
          SkyCameraMediaRendition(
            id: 'alt',
            skinId: 'alt_skin',
            mediaType: SkyCameraMediaType.photo,
            path: alternateOverlay.path,
            previewImagePath: alternateOverlay.path,
          ),
        ],
      ),
    );

    await repository.deleteCaptureIds(['delete-me']);

    expect(await repository.getCaptures(), isEmpty);
    expect(await original.exists(), isFalse);
    expect(await overlay.exists(), isFalse);
    expect(await alternateOverlay.exists(), isFalse);
  });

  test('loads legacy photo-only records with overlay fallback', () async {
    final tempDir = await Directory.systemTemp.createTemp('sky-camera-legacy');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = await databaseFactoryIo.openDatabase(
      p.join(tempDir.path, 'media.db'),
    );
    addTearDown(database.close);
    final appDatabase = AppDatabase.test(database: database);
    final repository = SkyCameraMediaRepository(database: appDatabase);

    await appDatabase.skyCameraMediaStore
        .record('legacy')
        .put(appDatabase.database, <String, Object?>{
          'id': 'legacy',
          'capturedAt': DateTime(2026, 6, 30, 12, 0).toIso8601String(),
          'originalPath': '/tmp/legacy.jpg',
          'capturedOverlayPath': '/tmp/legacy-overlay.png',
          'snapshot': _snapshot(
            capturedAt: DateTime(2026, 6, 30, 12, 0),
            originCode: 'LHR',
            destinationCode: 'JFK',
            outsideTemperatureCelsius: -50.0,
          ).toJson(),
        });

    final captures = await repository.getCaptures();

    expect(captures.single.mediaType, SkyCameraMediaType.photo);
    expect(captures.single.sourcePath, '/tmp/legacy.jpg');
    expect(captures.single.galleryImagePath, '/tmp/legacy-overlay.png');
    expect(captures.single.renditions.single.skinId, 'legacy_overlay');
    expect(captures.single.outsideTemperatureCelsius, -50.0);
  });

  test('stores app-document paths as relative records', () async {
    final tempDir = await Directory.systemTemp.createTemp('sky-camera-paths');
    addTearDown(() => tempDir.delete(recursive: true));
    final database = await databaseFactoryIo.openDatabase(
      p.join(tempDir.path, 'media.db'),
    );
    addTearDown(database.close);
    final appDatabase = AppDatabase.test(database: database);
    final repository = SkyCameraMediaRepository(database: appDatabase);

    final docsDir = await Directory.systemTemp.createTemp('sky-camera-docs');
    addTearDown(() => docsDir.delete(recursive: true));

    final item = _item(
      id: 'relative',
      capturedAt: DateTime(2026, 7, 1, 14, 0),
      sourcePath: p.join(docsDir.path, 'sky_camera', 'captures', 'a.jpg'),
      renditionPath: p.join(
        docsDir.path,
        'sky_camera',
        'captures',
        'a_overlay.png',
      ),
    );

    final originalGetter = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(docsDir.path);
    addTearDown(() => PathProviderPlatform.instance = originalGetter);

    await repository.addCapture(item);
    final raw = await appDatabase.skyCameraMediaStore
        .record('relative')
        .get(appDatabase.database);

    expect(raw?['sourcePath'], 'sky_camera/captures/a.jpg');
    expect(raw?['previewImagePath'], 'sky_camera/captures/a_overlay.png');
  });

  test(
    'rebases legacy absolute document paths to current documents dir',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'sky-camera-rebase',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final database = await databaseFactoryIo.openDatabase(
        p.join(tempDir.path, 'media.db'),
      );
      addTearDown(database.close);
      final appDatabase = AppDatabase.test(database: database);
      final repository = SkyCameraMediaRepository(database: appDatabase);

      const oldDocumentsPath =
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents';
      final currentDocsDir = await Directory.systemTemp.createTemp(
        'sky-camera-current-docs',
      );
      addTearDown(() => currentDocsDir.delete(recursive: true));

      final originalGetter = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FakePathProviderPlatform(
        currentDocsDir.path,
      );
      addTearDown(() => PathProviderPlatform.instance = originalGetter);

      await appDatabase.skyCameraMediaStore.record('rebased').put(
        appDatabase.database,
        <String, Object?>{
          'id': 'rebased',
          'capturedAt': DateTime(2026, 7, 1, 12, 0).toIso8601String(),
          'mediaType': 'photo',
          'sourcePath': '$oldDocumentsPath/sky_camera/captures/photo.jpg',
          'previewImagePath':
              '$oldDocumentsPath/sky_camera/captures/photo_overlay.png',
          'selectedRenditionId': 'default',
          'renditions': [
            {
              'id': 'default',
              'skinId': 'flymap_default_v1',
              'mediaType': 'photo',
              'path': '$oldDocumentsPath/sky_camera/captures/photo_overlay.png',
              'previewImagePath':
                  '$oldDocumentsPath/sky_camera/captures/photo_overlay.png',
            },
          ],
          'snapshot': _snapshot(
            capturedAt: DateTime(2026, 7, 1, 12, 0),
            originCode: 'LHR',
            destinationCode: 'JFK',
          ).toJson(),
        },
      );

      final captures = await repository.getCaptures();

      expect(
        captures.single.sourcePath,
        p.join(currentDocsDir.path, 'sky_camera', 'captures', 'photo.jpg'),
      );
      expect(
        captures.single.galleryImagePath,
        p.join(
          currentDocsDir.path,
          'sky_camera',
          'captures',
          'photo_overlay.png',
        ),
      );
    },
  );

  test('persists video items with multiple skins and track points', () async {
    final repository = await _buildRepository('video-renditions');
    final item = SkyCameraMediaItem(
      id: 'video-1',
      capturedAt: DateTime(2026, 7, 1, 12, 0),
      mediaType: SkyCameraMediaType.video,
      sourcePath: '/tmp/video-1.mp4',
      snapshot: _snapshot(
        capturedAt: DateTime(2026, 7, 1, 12, 0),
        originCode: 'LHR',
        destinationCode: 'SIN',
        latitude: 51.47,
        longitude: -0.45,
        outsideTemperatureCelsius: -55.2,
      ),
      renditions: const [
        SkyCameraMediaRendition(
          id: 'default',
          skinId: 'flymap_default_v1',
          mediaType: SkyCameraMediaType.video,
          path: '/tmp/video-1-overlay.mp4',
          previewImagePath: '/tmp/video-1-overlay.jpg',
        ),
        SkyCameraMediaRendition(
          id: 'clean',
          skinId: 'clean',
          mediaType: SkyCameraMediaType.video,
          path: '/tmp/video-1-clean.mp4',
          previewImagePath: '/tmp/video-1-clean.jpg',
        ),
      ],
      trackPoints: const [
        SkyCameraMediaTrackPoint(
          offsetMs: 0,
          latitude: 51.47,
          longitude: -0.45,
          altitudeMeters: 100.0,
        ),
        SkyCameraMediaTrackPoint(
          offsetMs: 1000,
          latitude: 51.48,
          longitude: -0.40,
          speedMetersPerSecond: 200.0,
        ),
      ],
      latitude: 51.47,
      longitude: -0.45,
      previewImagePath: '/tmp/video-1-poster.jpg',
      selectedRenditionId: 'clean',
      durationMs: 23000,
      outsideTemperatureCelsius: -55.2,
    );

    await repository.addCapture(item);
    final captures = await repository.getCaptures();

    expect(captures.single.mediaType, SkyCameraMediaType.video);
    expect(captures.single.sharePath, '/tmp/video-1-clean.mp4');
    expect(captures.single.galleryImagePath, '/tmp/video-1-clean.jpg');
    expect(captures.single.trackPoints, hasLength(2));
    expect(captures.single.durationMs, 23000);
    expect(captures.single.outsideTemperatureCelsius, -55.2);
  });
}

Future<SkyCameraMediaRepository> _buildRepository(String name) async {
  final tempDir = await Directory.systemTemp.createTemp('sky-camera-$name');
  addTearDown(() => tempDir.delete(recursive: true));
  final database = await databaseFactoryIo.openDatabase(
    p.join(tempDir.path, 'media.db'),
  );
  addTearDown(database.close);
  return SkyCameraMediaRepository(
    database: AppDatabase.test(database: database),
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

SkyCameraMediaItem _item({
  required String id,
  required DateTime capturedAt,
  String? flightId,
  String sourcePath = '/tmp/original.jpg',
  String? renditionPath,
  String originCode = '',
  String destinationCode = '',
  double? latitude,
  double? longitude,
  double? outsideTemperatureCelsius,
  List<SkyCameraMediaRendition> extraRenditions = const [],
}) {
  return SkyCameraMediaItem(
    id: id,
    capturedAt: capturedAt,
    mediaType: SkyCameraMediaType.photo,
    sourcePath: sourcePath,
    flightId: flightId,
    latitude: latitude,
    longitude: longitude,
    snapshot: _snapshot(
      capturedAt: capturedAt,
      originCode: originCode,
      destinationCode: destinationCode,
      latitude: latitude,
      longitude: longitude,
      outsideTemperatureCelsius: outsideTemperatureCelsius,
    ),
    renditions: [
      SkyCameraMediaRendition(
        id: 'default',
        skinId: 'flymap_default_v1',
        mediaType: SkyCameraMediaType.photo,
        path: renditionPath ?? '/tmp/$id-overlay.png',
        previewImagePath: renditionPath ?? '/tmp/$id-overlay.png',
      ),
      ...extraRenditions,
    ],
    trackPoints: const [],
    previewImagePath: renditionPath ?? '/tmp/$id-overlay.png',
    selectedRenditionId: 'default',
    outsideTemperatureCelsius: outsideTemperatureCelsius,
  );
}

SkyCameraOverlaySnapshot _snapshot({
  required DateTime capturedAt,
  required String originCode,
  required String destinationCode,
  double? latitude,
  double? longitude,
  double? outsideTemperatureCelsius,
}) {
  return SkyCameraOverlaySnapshot(
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
    hasLiveLocation: latitude != null && longitude != null,
    latitude: latitude,
    longitude: longitude,
    headingDegrees: null,
    altitudeMeters: null,
    speedMetersPerSecond: null,
    outsideTemperatureCelsius: outsideTemperatureCelsius,
  );
}
