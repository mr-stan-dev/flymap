import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';

/// Collects the 1 Hz GPS/overlay timeline of one video recording.
///
/// Snapshots stream in at roughly 1 Hz already; the recorder keeps the first
/// snapshot of every elapsed second so the saved track has at most one
/// sample per second, with offsets relative to the recording start.
class SkyCameraVideoTrackRecorder {
  final List<SkyCameraVideoTrackSample> _samples = [];
  DateTime? _startedAt;
  int _lastSampledSecond = -1;

  bool get isRecording => _startedAt != null;

  void start({required DateTime startedAt}) {
    _samples.clear();
    _lastSampledSecond = -1;
    _startedAt = startedAt;
  }

  void addSnapshot(SkyCameraOverlaySnapshot snapshot, {required DateTime at}) {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    final offsetMs = at.difference(startedAt).inMilliseconds;
    if (offsetMs < 0) return;
    final second = offsetMs ~/ 1000;
    if (second <= _lastSampledSecond) return;
    _lastSampledSecond = second;
    _samples.add(
      SkyCameraVideoTrackSample(offsetMs: offsetMs, snapshot: snapshot),
    );
  }

  List<SkyCameraVideoTrackSample> stop() {
    _startedAt = null;
    return List<SkyCameraVideoTrackSample>.unmodifiable(_samples);
  }
}
