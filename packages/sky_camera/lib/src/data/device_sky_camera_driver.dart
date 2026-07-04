import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/services/sky_camera_driver.dart';

class DeviceSkyCameraDriver implements SkyCameraDriver {
  DeviceSkyCameraDriver();

  CameraController? _controller;
  CameraDescription? _camera;
  SkyCameraFlashState _flashState = SkyCameraFlashState.off;
  double _minZoomLevel = 1.0;
  double _maxZoomLevel = 1.0;
  Future<void> _lifecycleOperation = Future<void>.value();

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  SkyCameraFlashState get flashState => _flashState;

  @override
  Future<void> initialize() async {
    await _runLifecycleOperation(() async {
      if (isInitialized) return;
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('no_camera', 'No cameras are available.');
      }
      CameraDescription? selectedCamera;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }
      _camera = selectedCamera ?? cameras.first;
      final controller = CameraController(
        _camera!,
        // The platform high-quality preset requests the standard 16:9 camera
        // stream. Captures are still center-cropped as a platform safeguard.
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();
      await _runBestEffort(
        () => controller.lockCaptureOrientation(DeviceOrientation.portraitUp),
      );
      await _configureCaptureDefaults(controller);
      await _runBestEffort(_applyFlashMode);
      try {
        _minZoomLevel = await controller.getMinZoomLevel();
        _maxZoomLevel = await controller.getMaxZoomLevel();
        await controller.setZoomLevel(_minZoomLevel);
      } catch (_) {
        _minZoomLevel = 1.0;
        _maxZoomLevel = 1.0;
      }
    });
  }

  @override
  Future<void> dispose() async {
    await _runLifecycleOperation(() async {
      final controller = _controller;
      _controller = null;
      _camera = null;
      _minZoomLevel = 1.0;
      _maxZoomLevel = 1.0;
      if (controller == null) return;
      try {
        await controller.dispose();
      } on PlatformException catch (error) {
        if (_isBenignPreviewReleaseException(error)) {
          return;
        }
        rethrow;
      }
    });
  }

  @override
  Future<void> onAppLifecycleStateChanged(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive) {
      await dispose();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      await initialize();
    }
  }

  @override
  Future<SkyCameraCapturedPhoto> capturePhoto() async {
    final controller = _requireController();
    final file = await controller.takePicture();
    final bytes = await file.readAsBytes();
    final extension = file.path.split('.').last.toLowerCase();
    return SkyCameraCapturedPhoto(
      bytes: bytes,
      fileExtension: extension.isEmpty ? 'jpg' : extension,
      capturedAt: DateTime.now(),
    );
  }

  @override
  Future<void> toggleFlash() async {
    switch (_flashState) {
      case SkyCameraFlashState.off:
        _flashState = SkyCameraFlashState.auto;
      case SkyCameraFlashState.auto:
        _flashState = SkyCameraFlashState.on;
      case SkyCameraFlashState.on:
        _flashState = SkyCameraFlashState.off;
    }
    await _applyFlashMode();
  }

  @override
  Future<void> setFocusPoint(Offset normalizedPoint) async {
    final controller = _requireController();
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.setFocusPoint(normalizedPoint);
      await controller.setExposurePoint(normalizedPoint);
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  Future<SkyCameraZoomBounds> getZoomBounds() async {
    final controller = _requireController();
    try {
      _minZoomLevel = await controller.getMinZoomLevel();
      _maxZoomLevel = await controller.getMaxZoomLevel();
    } catch (_) {
      _minZoomLevel = 1.0;
      _maxZoomLevel = 1.0;
    }
    return SkyCameraZoomBounds(min: _minZoomLevel, max: _maxZoomLevel);
  }

  @override
  Future<void> setZoomLevel(double zoomLevel) async {
    final controller = _requireController();
    final clampedZoom = zoomLevel.clamp(_minZoomLevel, _maxZoomLevel);
    try {
      await controller.setZoomLevel(clampedZoom);
    } catch (_) {
      // Best-effort only.
    }
  }

  @override
  Widget buildPreview() {
    final controller = _requireController();
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: previewSize.height,
          height: previewSize.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  CameraController _requireController() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraException(
        'camera_not_initialized',
        'Camera controller is not initialized.',
      );
    }
    return controller;
  }

  Future<void> _applyFlashMode() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    switch (_flashState) {
      case SkyCameraFlashState.off:
        await controller.setFlashMode(FlashMode.off);
      case SkyCameraFlashState.auto:
        await controller.setFlashMode(FlashMode.auto);
      case SkyCameraFlashState.on:
        await controller.setFlashMode(FlashMode.always);
    }
  }

  Future<void> _configureCaptureDefaults(CameraController controller) async {
    try {
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _runBestEffort(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Optional camera capabilities must not invalidate a working preview.
    }
  }

  bool _isBenignPreviewReleaseException(PlatformException error) {
    final message =
        '${error.code} ${error.message ?? ''} ${error.details ?? ''}';
    return message.contains('releaseFlutterSurfaceTexture()') &&
        message.contains('flutterSurfaceProducer for the camera preview');
  }

  Future<void> _runLifecycleOperation(Future<void> Function() action) {
    final operation = _lifecycleOperation.then((_) => action());
    _lifecycleOperation = operation.catchError((_) {});
    return operation;
  }
}
