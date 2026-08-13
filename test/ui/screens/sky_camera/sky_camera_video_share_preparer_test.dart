import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_rendition_service.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_share_preparer.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  setUpAll(() => LocaleSettings.setLocaleSync(AppLocale.en));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<MetricUnitsRepository>(MetricUnitsRepository());
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('prepares every unresolved video in a media collection', (
    tester,
  ) async {
    late BuildContext context;
    final service = _FakeRenditionService();
    final captures = [
      _mediaItem(id: 'photo', mediaType: SkyCameraMediaType.photo),
      _mediaItem(id: 'raw-1', mediaType: SkyCameraMediaType.video),
      _mediaItem(
        id: 'prepared',
        mediaType: SkyCameraMediaType.video,
        withRendition: true,
      ),
      _mediaItem(id: 'raw-2', mediaType: SkyCameraMediaType.video),
    ];
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final preparation = prepareSkyCameraMediaForSharing(
      context,
      captures: captures,
      renditionService: service,
    );
    await tester.pumpAndSettle();
    final prepared = await preparation;

    expect(service.preparedIds, ['raw-1', 'raw-2']);
    expect(prepared, isNotNull);
    expect(
      prepared!
          .where((capture) => capture.isVideo)
          .map((capture) => capture.sharePath),
      [
        '/tmp/raw-1-overlay.mp4',
        '/tmp/prepared-overlay.mp4',
        '/tmp/raw-2-overlay.mp4',
      ],
    );
  });

  testWidgets('shows a specific message when rendition storage is too low', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const Scaffold();
            },
          ),
        ),
      ),
    );

    final preparation = prepareSkyCameraMediaForSharing(
      context,
      captures: [_mediaItem(id: 'raw', mediaType: SkyCameraMediaType.video)],
      renditionService: _LowStorageRenditionService(),
    );
    await tester.pumpAndSettle();

    expect(await preparation, isNull);
    expect(
      find.text(context.t.skyCamera.lowStorageVideoExport),
      findsOneWidget,
    );
  });

  test('reserves room for the burned MP4 before rendering frames', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'flymap-rendition-storage-',
    );
    addTearDown(() => tempDirectory.delete(recursive: true));
    final source = File('${tempDirectory.path}/source.mp4');
    await source.writeAsBytes(List<int>.filled(100, 1));
    final item = _mediaItem(
      id: 'low-storage',
      mediaType: SkyCameraMediaType.video,
    ).copyWith(sourcePath: source.path);
    final service = SkyCameraVideoRenditionService(
      repository: SkyCameraMediaRepository.forTest(),
      availableStorageBytes: () async => 199,
      minimumFreeBytesAfterExport: 100,
    );

    await expectLater(
      service.ensureOverlayRendition(item, strings: _testStrings),
      throwsA(isA<SkyCameraRenditionInsufficientStorage>()),
    );
  });
}

const _testStrings = SkyCameraStrings(
  loadingCamera: 'Loading',
  loadingGpsData: 'Loading GPS',
  retry: 'Retry',
  close: 'Close',
  zoom: 'Zoom',
  flash: 'Flash',
  captureFailed: 'Failed',
  cameraUnavailable: 'Unavailable',
  cameraPermissionDenied: 'Denied',
  savedMessage: 'Saved',
  share: 'Share',
  telemetrySpeed: 'Speed',
  telemetryAltitude: 'Altitude',
  telemetryHeading: 'Heading',
  telemetryTime: 'Time',
  contextCaption: 'Context',
  mapCaption: 'Map',
  coordinatesCaption: 'Coordinates',
  noValuePlaceholder: '--',
  altitudeUnit: SkyCameraAltitudeUnit.meter,
  speedUnit: SkyCameraSpeedUnit.kmh,
  temperatureUnit: SkyCameraTemperatureUnit.celsius,
  dateDisplayFormat: SkyCameraDateDisplayFormat.dayMonthYear,
);

SkyCameraMediaItem _mediaItem({
  required String id,
  required SkyCameraMediaType mediaType,
  bool withRendition = false,
}) {
  final capturedAt = DateTime(2026, 7, 13, 12);
  final extension = mediaType == SkyCameraMediaType.video ? 'mp4' : 'jpg';
  return SkyCameraMediaItem(
    id: id,
    capturedAt: capturedAt,
    mediaType: mediaType,
    sourcePath: '/tmp/$id.$extension',
    snapshot: SkyCameraOverlaySnapshot(
      timestamp: capturedAt,
      routeLabel: 'LHR → BCN',
      originCode: 'LHR',
      destinationCode: 'BCN',
      originCountryCode: 'GB',
      destinationCountryCode: 'ES',
      contextLabel: '',
      mapStatePlaceholder: '',
      hasLiveLocation: false,
      latitude: null,
      longitude: null,
      headingDegrees: null,
      altitudeMeters: null,
      speedMetersPerSecond: null,
    ),
    renditions: withRendition
        ? [
            SkyCameraMediaRendition(
              id: SkyCameraVideoRenditionService.renditionId,
              skinId: 'flymap_default_v1',
              mediaType: mediaType,
              path: '/tmp/$id-overlay.$extension',
            ),
          ]
        : const [],
    trackPoints: const [],
    selectedRenditionId: withRendition
        ? SkyCameraVideoRenditionService.renditionId
        : null,
  );
}

class _FakeRenditionService extends SkyCameraVideoRenditionService {
  _FakeRenditionService()
    : super(repository: SkyCameraMediaRepository.forTest());

  final List<String> preparedIds = [];

  @override
  Future<SkyCameraMediaItem> ensureOverlayRendition(
    SkyCameraMediaItem item, {
    required SkyCameraStrings strings,
    void Function(double fraction)? onProgress,
    SkyCameraRenditionCancellation? cancellation,
  }) async {
    preparedIds.add(item.id);
    onProgress?.call(1);
    return item.copyWith(
      renditions: [
        SkyCameraMediaRendition(
          id: SkyCameraVideoRenditionService.renditionId,
          skinId: 'flymap_default_v1',
          mediaType: SkyCameraMediaType.video,
          path: '/tmp/${item.id}-overlay.mp4',
        ),
      ],
      selectedRenditionId: SkyCameraVideoRenditionService.renditionId,
    );
  }
}

class _LowStorageRenditionService extends SkyCameraVideoRenditionService {
  _LowStorageRenditionService()
    : super(repository: SkyCameraMediaRepository.forTest());

  @override
  Future<SkyCameraMediaItem> ensureOverlayRendition(
    SkyCameraMediaItem item, {
    required SkyCameraStrings strings,
    void Function(double fraction)? onProgress,
    SkyCameraRenditionCancellation? cancellation,
  }) async {
    throw const SkyCameraRenditionInsufficientStorage();
  }
}
