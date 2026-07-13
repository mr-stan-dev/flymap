import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_overlay_timeline.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  final capturedAt = DateTime(2026, 7, 13, 12, 0);

  SkyCameraOverlaySnapshot baseSnapshot() {
    return SkyCameraOverlaySnapshot(
      timestamp: capturedAt,
      routeLabel: 'London → Rome',
      originCode: 'LHR',
      destinationCode: 'FCO',
      originCountryCode: 'GB',
      destinationCountryCode: 'IT',
      contextLabel: 'context',
      mapStatePlaceholder: 'map',
      hasLiveLocation: true,
      latitude: 48.0,
      longitude: 5.0,
      headingDegrees: 140,
      altitudeMeters: 10000,
      speedMetersPerSecond: 220,
    );
  }

  SkyCameraMediaItem buildItem(List<SkyCameraMediaTrackPoint> trackPoints) {
    return SkyCameraMediaItem(
      id: 'video-1',
      capturedAt: capturedAt,
      mediaType: SkyCameraMediaType.video,
      sourcePath: '/tmp/video-1_original.mp4',
      snapshot: baseSnapshot(),
      renditions: const [],
      trackPoints: trackPoints,
    );
  }

  test('resolves the latest track point at or before the offset', () {
    final item = buildItem([
      const SkyCameraMediaTrackPoint(
        offsetMs: 0,
        latitude: 48.0,
        longitude: 5.0,
        speedMetersPerSecond: 200,
        altitudeMeters: 10000,
        horizontalAccuracyMeters: 8,
      ),
      const SkyCameraMediaTrackPoint(
        offsetMs: 1000,
        latitude: 48.1,
        longitude: 5.1,
        speedMetersPerSecond: 210,
        altitudeMeters: 10050,
      ),
      const SkyCameraMediaTrackPoint(
        offsetMs: 2000,
        latitude: 48.2,
        longitude: 5.2,
        speedMetersPerSecond: 220,
        altitudeMeters: 10100,
      ),
    ]);
    final timeline = SkyCameraVideoOverlayTimeline(item);

    final midSecond = timeline.snapshotAt(1500);
    expect(midSecond.latitude, 48.1);
    expect(midSecond.speedMetersPerSecond, 210);
    expect(midSecond.hasLiveLocation, isTrue);
    expect(
      midSecond.timestamp,
      capturedAt.add(const Duration(milliseconds: 1500)),
    );
    // Altitude at cruise: the estimated outside temperature is recomputed.
    expect(midSecond.outsideTemperatureIsEstimated, isTrue);

    final start = timeline.snapshotAt(0);
    expect(start.speedMetersPerSecond, 200);
    expect(start.horizontalAccuracyMeters, 8);

    final tail = timeline.snapshotAt(30000);
    expect(tail.latitude, 48.2);
  });

  test('keeps route context but drops values without any GPS fix', () {
    final timeline = SkyCameraVideoOverlayTimeline(buildItem(const []));

    final snapshot = timeline.snapshotAt(5000);
    expect(snapshot.routeLabel, 'London → Rome');
    expect(snapshot.hasLiveLocation, isFalse);
    expect(snapshot.latitude, isNull);
    expect(snapshot.speedMetersPerSecond, isNull);
    expect(
      snapshot.timestamp,
      capturedAt.add(const Duration(seconds: 5)),
    );
  });
}
