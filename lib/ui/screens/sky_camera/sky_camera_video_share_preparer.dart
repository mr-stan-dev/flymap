import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/sky_camera_media_item.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_strings_builder.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_rendition_service.dart';
import 'package:get_it/get_it.dart';

/// Ensures every video has an overlay-burned rendition before it is shared.
///
/// Returns updated media items, or `null` when preparation failed or the
/// calling route was disposed while the work was running.
Future<List<SkyCameraMediaItem>?> prepareSkyCameraMediaForSharing(
  BuildContext context, {
  required List<SkyCameraMediaItem> captures,
  SkyCameraVideoRenditionService? renditionService,
}) async {
  final pendingVideoIds = {
    for (final capture in captures)
      if (capture.isVideo && !_hasShareableVideoRendition(capture)) capture.id,
  };
  if (pendingVideoIds.isEmpty) {
    return List<SkyCameraMediaItem>.of(captures);
  }

  final preparingLabel = context.t.skyCamera.preparingVideo;
  final failedLabel = context.t.skyCamera.captureFailed;
  final strings = await FlymapSkyCameraStringsBuilder.build(context);
  if (!context.mounted) return null;

  final progress = ValueNotifier<double>(0);
  unawaited(
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, fraction, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(preparingLabel)),
                    const SizedBox(width: 12),
                    Text(
                      '${(fraction * 100).round()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: fraction, minHeight: 6),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  final prepared = List<SkyCameraMediaItem>.of(captures);
  var completedVideos = 0;
  try {
    final service =
        renditionService ?? GetIt.I<SkyCameraVideoRenditionService>();
    for (var index = 0; index < prepared.length; index++) {
      final capture = prepared[index];
      if (!pendingVideoIds.contains(capture.id)) continue;
      prepared[index] = await service.ensureOverlayRendition(
        capture,
        strings: strings,
        onProgress: (fraction) {
          progress.value =
              (completedVideos + fraction.clamp(0.0, 1.0)) /
              pendingVideoIds.length;
        },
      );
      completedVideos += 1;
      progress.value = completedVideos / pendingVideoIds.length;
    }
    if (!context.mounted) return null;
    Navigator.of(context, rootNavigator: true).pop();
    return prepared;
  } catch (_) {
    if (!context.mounted) return null;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(failedLabel)));
    return null;
  } finally {
    // Let the dialog's last frame read the notifier before it goes away.
    WidgetsBinding.instance.addPostFrameCallback((_) => progress.dispose());
  }
}

bool _hasShareableVideoRendition(SkyCameraMediaItem capture) {
  final rendition = capture.selectedRendition;
  return rendition != null &&
      rendition.mediaType == SkyCameraMediaType.video &&
      rendition.path.trim().isNotEmpty;
}
