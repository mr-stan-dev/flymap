import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_share_service.dart';
import 'package:sky_camera/sky_camera.dart';

void main() {
  test('rejects a video without an overlay rendition before sharing', () async {
    final analytics = _FakeAppAnalytics();
    final service = FlymapSkyCameraShareService(analytics: analytics);
    final capture = _unrenderedVideo();

    expect(capture.sharePath, capture.sourcePath);
    await expectLater(
      service.shareMediaItems(
        captures: [capture],
        sharePositionOrigin: Rect.zero,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('overlay rendition'),
        ),
      ),
    );
    expect(analytics.loggedEvents, isEmpty);
  });
}

SkyCameraMediaItem _unrenderedVideo() {
  final capturedAt = DateTime(2026, 7, 13, 12);
  return SkyCameraMediaItem(
    id: 'video-1',
    capturedAt: capturedAt,
    mediaType: SkyCameraMediaType.video,
    sourcePath: '/tmp/video-1.mp4',
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
    renditions: const [],
    trackPoints: const [],
  );
}

class _FakeAppAnalytics implements AppAnalytics {
  final List<AnalyticsEvent> loggedEvents = [];

  @override
  Future<void> log(AnalyticsEvent event) async {
    loggedEvents.add(event);
  }

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}
}
