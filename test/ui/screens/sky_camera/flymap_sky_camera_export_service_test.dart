import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_export_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PathProviderPlatform originalPathProvider;
  late Directory documentsDirectory;

  setUp(() async {
    originalPathProvider = PathProviderPlatform.instance;
    documentsDirectory = await Directory.systemTemp.createTemp(
      'sky-camera-export-test',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      documentsDirectory.path,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await documentsDirectory.delete(recursive: true);
  });

  test('scoped export persists the explicitly selected flight ID', () async {
    final repository = _RecordingMediaRepository();
    final service = FlymapSkyCameraExportService.forFlight(
      mediaRepository: repository,
      flightId: 'selected-flight',
    );
    final capturedAt = DateTime(2026, 7, 4, 12);

    await service.saveCapture(
      originalPhoto: SkyCameraCapturedPhoto(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'jpg',
        capturedAt: capturedAt,
      ),
      snapshot: SkyCameraOverlaySnapshot(
        timestamp: capturedAt,
        routeLabel: 'London - Berlin',
        originCode: 'LHR',
        destinationCode: 'BER',
        originCountryCode: 'GB',
        destinationCountryCode: 'DE',
        contextLabel: '',
        mapStatePlaceholder: '',
        hasLiveLocation: false,
        latitude: null,
        longitude: null,
        headingDegrees: null,
        altitudeMeters: null,
        speedMetersPerSecond: null,
      ),
      overlayBytes: Uint8List.fromList([4, 5, 6]),
    );

    expect(repository.savedItem?.flightId, 'selected-flight');
  });
}

class _RecordingMediaRepository extends SkyCameraMediaRepository {
  _RecordingMediaRepository() : super.forTest();

  SkyCameraMediaItem? savedItem;

  @override
  Future<void> addCapture(SkyCameraMediaItem item) async {
    savedItem = item;
  }
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
