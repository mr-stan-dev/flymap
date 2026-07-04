import 'dart:ui';

import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraShareService implements SkyCameraShareService {
  FlymapSkyCameraShareService({required AppAnalytics analytics})
    : _analytics = analytics;

  final AppAnalytics _analytics;

  @override
  Future<void> shareCapture({
    required SkyCameraSavedCapture capture,
    required Rect sharePositionOrigin,
  }) async {
    await _analytics.log(const SkyPhotoShareEvent());
    await Share.shareXFiles([
      XFile(capture.overlayPath),
    ], sharePositionOrigin: sharePositionOrigin);
  }

  Future<void> shareMediaItems({
    required List<SkyCameraMediaItem> captures,
    required Rect sharePositionOrigin,
  }) async {
    final files = [
      for (final capture in captures)
        if (capture.sharePath.trim().isNotEmpty) XFile(capture.sharePath),
    ];
    if (files.isEmpty) return;
    await _analytics.log(const SkyPhotoShareEvent());
    await Share.shareXFiles(files, sharePositionOrigin: sharePositionOrigin);
  }
}
