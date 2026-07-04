import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/domain/observers/sky_camera_observer.dart';
import 'package:sky_camera/src/presentation/sky_camera_metrics_position.dart';
import 'package:sky_camera/src/domain/services/sky_camera_driver.dart';
import 'package:sky_camera/src/domain/services/sky_camera_export_service.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';
import 'package:sky_camera/src/rendering/sky_camera_overlay_composer.dart';
import 'package:sky_camera/src/rendering/sky_camera_photo_cropper.dart';

class SkyCameraCaptureCoordinator {
  const SkyCameraCaptureCoordinator({
    required this.driver,
    required this.observer,
    required this.exportService,
    required this.overlayComposer,
    required this.photoCropper,
    required this.strings,
  });

  final SkyCameraDriver driver;
  final SkyCameraObserver observer;
  final SkyCameraExportService exportService;
  final SkyCameraOverlayComposer overlayComposer;
  final SkyCameraPhotoCropper photoCropper;
  final SkyCameraStrings strings;

  Future<SkyCameraSavedCapture> capture({
    required SkyCameraOverlaySnapshot snapshot,
    required SkyCameraMetricsPosition metricsPosition,
  }) async {
    final capturedPhoto = await driver.capturePhoto();
    final photo = await photoCropper.cropToMediaFormat(capturedPhoto);
    await observer.onPhotoCaptured(snapshot: snapshot);
    final overlayBytes = await overlayComposer.compose(
      originalBytes: photo.bytes,
      snapshot: snapshot,
      strings: strings,
      metricsPosition: metricsPosition,
    );
    final saved = await exportService.saveCapture(
      originalPhoto: photo,
      snapshot: snapshot,
      overlayBytes: overlayBytes,
    );
    return saved;
  }
}
