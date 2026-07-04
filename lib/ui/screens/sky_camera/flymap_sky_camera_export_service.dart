import 'dart:io';

import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraExportService implements SkyCameraExportService {
  FlymapSkyCameraExportService({
    required FlightRepository flightRepository,
    required SkyCameraMediaRepository mediaRepository,
  }) : _flightRepository = flightRepository,
       _mediaRepository = mediaRepository,
       _fixedFlightId = null;

  FlymapSkyCameraExportService.forFlight({
    required SkyCameraMediaRepository mediaRepository,
    required String flightId,
  }) : _flightRepository = null,
       _mediaRepository = mediaRepository,
       _fixedFlightId = _normalizeFlightId(flightId);

  final FlightRepository? _flightRepository;
  final SkyCameraMediaRepository _mediaRepository;
  final String? _fixedFlightId;

  FlymapSkyCameraExportService scopedToFlight(String flightId) {
    return FlymapSkyCameraExportService.forFlight(
      mediaRepository: _mediaRepository,
      flightId: flightId,
    );
  }

  @override
  Future<SkyCameraSavedCapture> saveCapture({
    required SkyCameraCapturedPhoto originalPhoto,
    required SkyCameraOverlaySnapshot snapshot,
    required List<int> overlayBytes,
  }) async {
    final docsDirectory = await getApplicationDocumentsDirectory();
    final captureDirectory = Directory(
      p.join(docsDirectory.path, 'sky_camera', 'captures'),
    );
    await captureDirectory.create(recursive: true);

    final baseName = originalPhoto.capturedAt
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final originalPath = p.join(
      captureDirectory.path,
      '${baseName}_original.${originalPhoto.fileExtension}',
    );
    final overlayPath = p.join(
      captureDirectory.path,
      '${baseName}_overlay.png',
    );

    await File(originalPath).writeAsBytes(originalPhoto.bytes, flush: true);
    await File(overlayPath).writeAsBytes(overlayBytes, flush: true);
    final flightId = await _resolveFlightId();
    await _mediaRepository.addCapture(
      SkyCameraMediaItem(
        id: baseName,
        capturedAt: originalPhoto.capturedAt,
        mediaType: SkyCameraMediaType.photo,
        sourcePath: originalPath,
        snapshot: snapshot,
        renditions: [
          SkyCameraMediaRendition(
            id: 'default',
            skinId: 'flymap_default_v1',
            mediaType: SkyCameraMediaType.photo,
            path: overlayPath,
            previewImagePath: overlayPath,
            createdAt: originalPhoto.capturedAt,
          ),
        ],
        trackPoints: const [],
        flightId: flightId,
        latitude: snapshot.latitude,
        longitude: snapshot.longitude,
        previewImagePath: overlayPath,
        selectedRenditionId: 'default',
        outsideTemperatureCelsius: snapshot.outsideTemperatureCelsius,
      ),
    );

    return SkyCameraSavedCapture(
      id: baseName,
      originalPath: originalPath,
      overlayPath: overlayPath,
    );
  }

  Future<String?> _resolveFlightId() async {
    final fixedFlightId = _fixedFlightId;
    if (fixedFlightId != null) return fixedFlightId;
    final flights = await _flightRepository!.getAllFlights();
    final inProgressFlights = flights
        .where((flight) => flight.status == FlightStatus.inProgress)
        .toList(growable: false);
    if (inProgressFlights.isEmpty) return null;
    inProgressFlights.sort((a, b) {
      final aDate = a.inProgressAt ?? a.createdAt;
      final bDate = b.inProgressAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });
    final flight = inProgressFlights.first;
    return flight.id;
  }

  static String _normalizeFlightId(String flightId) {
    final normalizedFlightId = flightId.trim();
    if (normalizedFlightId.isEmpty) {
      throw ArgumentError.value(flightId, 'flightId', 'Must not be empty.');
    }
    return normalizedFlightId;
  }
}
