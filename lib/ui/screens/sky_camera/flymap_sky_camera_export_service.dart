import 'dart:io';

import 'package:flymap/data/video_tools/video_tools_channel.dart';
import 'package:flymap/domain/entity/flight_status.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraExportService implements SkyCameraExportService {
  FlymapSkyCameraExportService({
    required FlightRepository flightRepository,
    required SkyCameraMediaRepository mediaRepository,
    VideoToolsChannel videoTools = const VideoToolsChannel(),
  }) : _flightRepository = flightRepository,
       _mediaRepository = mediaRepository,
       _videoTools = videoTools,
       _fixedFlightId = null;

  FlymapSkyCameraExportService.forFlight({
    required SkyCameraMediaRepository mediaRepository,
    required String flightId,
    VideoToolsChannel videoTools = const VideoToolsChannel(),
  }) : _flightRepository = null,
       _mediaRepository = mediaRepository,
       _videoTools = videoTools,
       _fixedFlightId = _normalizeFlightId(flightId);

  final FlightRepository? _flightRepository;
  final SkyCameraMediaRepository _mediaRepository;
  final VideoToolsChannel _videoTools;
  final String? _fixedFlightId;
  final Logger _logger = const Logger('SkyCameraExport');

  FlymapSkyCameraExportService scopedToFlight(String flightId) {
    return FlymapSkyCameraExportService.forFlight(
      mediaRepository: _mediaRepository,
      flightId: flightId,
      videoTools: _videoTools,
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

  @override
  Future<SkyCameraSavedCapture> saveVideoCapture({
    required SkyCameraCapturedVideo video,
    required SkyCameraOverlaySnapshot snapshot,
    required List<SkyCameraVideoTrackSample> track,
  }) async {
    final docsDirectory = await getApplicationDocumentsDirectory();
    final captureDirectory = Directory(
      p.join(docsDirectory.path, 'sky_camera', 'captures'),
    );
    await captureDirectory.create(recursive: true);

    final baseName = video.capturedAt
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final originalPath = p.join(
      captureDirectory.path,
      '${baseName}_original.${video.fileExtension}',
    );
    await _moveFile(video.filePath, originalPath);

    // The poster drives every thumbnail. A native extraction failure
    // degrades to an icon tile rather than losing the recording.
    var posterPath = '';
    try {
      final posterBytes = await _videoTools.extractPoster(
        videoPath: originalPath,
      );
      posterPath = p.join(captureDirectory.path, '${baseName}_poster.png');
      await File(posterPath).writeAsBytes(posterBytes, flush: true);
    } catch (error) {
      _logger.error('Video poster extraction failed: $error');
      posterPath = '';
    }

    final flightId = await _resolveFlightId();
    await _mediaRepository.addCapture(
      SkyCameraMediaItem(
        id: baseName,
        capturedAt: video.capturedAt,
        mediaType: SkyCameraMediaType.video,
        sourcePath: originalPath,
        snapshot: snapshot,
        // The overlay rendition is created lazily at share/save time.
        renditions: const [],
        trackPoints: [
          for (final sample in track)
            if (sample.snapshot.latitude != null &&
                sample.snapshot.longitude != null)
              SkyCameraMediaTrackPoint(
                offsetMs: sample.offsetMs,
                latitude: sample.snapshot.latitude!,
                longitude: sample.snapshot.longitude!,
                headingDegrees: sample.snapshot.headingDegrees,
                altitudeMeters: sample.snapshot.altitudeMeters,
                speedMetersPerSecond: sample.snapshot.speedMetersPerSecond,
                horizontalAccuracyMeters:
                    sample.snapshot.horizontalAccuracyMeters,
              ),
        ],
        flightId: flightId,
        latitude: snapshot.latitude,
        longitude: snapshot.longitude,
        previewImagePath: posterPath.isEmpty ? null : posterPath,
        selectedRenditionId: null,
        durationMs: video.duration.inMilliseconds,
        outsideTemperatureCelsius: snapshot.outsideTemperatureCelsius,
      ),
    );

    return SkyCameraSavedCapture(
      id: baseName,
      originalPath: originalPath,
      overlayPath: posterPath,
      isVideo: true,
    );
  }

  Future<void> _moveFile(String fromPath, String toPath) async {
    final source = File(fromPath);
    try {
      await source.rename(toPath);
    } on FileSystemException {
      // rename fails across volumes (plugin temp dir → documents); copy.
      await source.copy(toPath);
      await source.delete();
    }
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
