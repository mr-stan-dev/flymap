import 'dart:ui';

import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sky_camera/sky_camera.dart';

class FlymapSkyCameraShareService implements SkyCameraShareService {
  @override
  Future<void> shareCapture({
    required SkyCameraSavedCapture capture,
    required Rect sharePositionOrigin,
  }) async {
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
    await Share.shareXFiles(files, sharePositionOrigin: sharePositionOrigin);
  }
}
