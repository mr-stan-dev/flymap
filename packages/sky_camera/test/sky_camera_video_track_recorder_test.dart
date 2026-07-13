import 'package:flutter_test/flutter_test.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  SkyCameraOverlaySnapshot snapshotAt(DateTime timestamp, double speed) {
    return SkyCameraOverlaySnapshot(
      timestamp: timestamp,
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
      speedMetersPerSecond: speed,
    );
  }

  test('keeps the first snapshot of each elapsed second', () {
    final recorder = SkyCameraVideoTrackRecorder();
    final start = DateTime(2026, 7, 13, 12, 0);
    recorder.start(startedAt: start);

    for (final offsetMs in [0, 300, 1100, 1900, 2500]) {
      recorder.addSnapshot(
        snapshotAt(start, offsetMs.toDouble()),
        at: start.add(Duration(milliseconds: offsetMs)),
      );
    }
    final track = recorder.stop();

    expect(track.map((sample) => sample.offsetMs), [0, 1100, 2500]);
    expect(track.first.snapshot.speedMetersPerSecond, 0);
    expect(track.last.snapshot.speedMetersPerSecond, 2500);
  });

  test('ignores snapshots outside an active recording', () {
    final recorder = SkyCameraVideoTrackRecorder();
    final start = DateTime(2026, 7, 13, 12, 0);

    recorder.addSnapshot(snapshotAt(start, 1), at: start);
    expect(recorder.isRecording, isFalse);

    recorder.start(startedAt: start);
    // Clock skew: a snapshot stamped before the start must not record.
    recorder.addSnapshot(
      snapshotAt(start, 2),
      at: start.subtract(const Duration(milliseconds: 5)),
    );
    expect(recorder.stop(), isEmpty);
  });

  test('restarting clears the previous track', () {
    final recorder = SkyCameraVideoTrackRecorder();
    final start = DateTime(2026, 7, 13, 12, 0);
    recorder.start(startedAt: start);
    recorder.addSnapshot(snapshotAt(start, 1), at: start);
    recorder.stop();

    final secondStart = start.add(const Duration(minutes: 1));
    recorder.start(startedAt: secondStart);
    recorder.addSnapshot(snapshotAt(secondStart, 9), at: secondStart);
    final track = recorder.stop();

    expect(track, hasLength(1));
    expect(track.single.snapshot.speedMetersPerSecond, 9);
  });
}
