import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/domain/policy/outside_temperature_policy.dart';
import 'package:sky_camera/sky_camera.dart';

/// Rebuilds the overlay snapshot for any moment of a recorded video from the
/// item's static context plus its 1 Hz GPS track — the single source of
/// truth for both live playback overlays and the share-time burn-in.
class SkyCameraVideoOverlayTimeline {
  SkyCameraVideoOverlayTimeline(this.item);

  final SkyCameraMediaItem item;

  SkyCameraOverlaySnapshot snapshotAt(int offsetMs) {
    final base = item.snapshot;
    final point = _pointAt(offsetMs);
    final timestamp = item.capturedAt.add(Duration(milliseconds: offsetMs));
    if (point == null) {
      // No GPS fix during the recording: keep the captured context but tick
      // the clock forward.
      return SkyCameraOverlaySnapshot(
        timestamp: timestamp,
        routeLabel: base.routeLabel,
        originCode: base.originCode,
        destinationCode: base.destinationCode,
        originCountryCode: base.originCountryCode,
        destinationCountryCode: base.destinationCountryCode,
        contextLabel: base.contextLabel,
        mapStatePlaceholder: base.mapStatePlaceholder,
        hasLiveLocation: false,
        latitude: null,
        longitude: null,
        headingDegrees: null,
        altitudeMeters: null,
        speedMetersPerSecond: null,
      );
    }

    final altitude = point.altitudeMeters;
    final temperature =
        altitude != null &&
            OutsideTemperaturePolicy.isAvailable(altitudeMeters: altitude)
        ? OutsideTemperaturePolicy.estimate(
            altitudeMeters: altitude,
            latitude: point.latitude,
            longitude: point.longitude,
            timestampUtc: timestamp.toUtc(),
          ).celsius
        : null;

    return SkyCameraOverlaySnapshot(
      timestamp: timestamp,
      routeLabel: base.routeLabel,
      originCode: base.originCode,
      destinationCode: base.destinationCode,
      originCountryCode: base.originCountryCode,
      destinationCountryCode: base.destinationCountryCode,
      contextLabel: base.contextLabel,
      mapStatePlaceholder: base.mapStatePlaceholder,
      hasLiveLocation: true,
      latitude: point.latitude,
      longitude: point.longitude,
      headingDegrees: point.headingDegrees,
      altitudeMeters: point.altitudeMeters,
      speedMetersPerSecond: point.speedMetersPerSecond,
      horizontalAccuracyMeters: point.horizontalAccuracyMeters,
      outsideTemperatureCelsius: temperature,
      outsideTemperatureIsEstimated: temperature != null,
    );
  }

  /// Latest track point at or before [offsetMs]; the first point covers any
  /// lead-in, so values never appear before the recording had a fix.
  SkyCameraMediaTrackPoint? _pointAt(int offsetMs) {
    SkyCameraMediaTrackPoint? current;
    for (final point in item.trackPoints) {
      if (point.offsetMs <= offsetMs) {
        current = point;
      } else {
        break;
      }
    }
    return current ?? (item.trackPoints.isEmpty ? null : item.trackPoints.first);
  }
}
