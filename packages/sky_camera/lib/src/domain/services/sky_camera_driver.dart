import 'package:flutter/material.dart';
import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';

enum SkyCameraFlashState { off, auto, on }

class SkyCameraZoomBounds {
  const SkyCameraZoomBounds({required this.min, required this.max});

  final double min;
  final double max;
}

abstract class SkyCameraDriver {
  bool get isInitialized;
  SkyCameraFlashState get flashState;

  Future<void> initialize();
  Future<void> dispose();
  Future<void> onAppLifecycleStateChanged(AppLifecycleState state);
  Future<SkyCameraCapturedPhoto> capturePhoto();
  Future<void> toggleFlash();
  Future<void> setFocusPoint(Offset normalizedPoint);
  Future<SkyCameraZoomBounds> getZoomBounds();
  Future<void> setZoomLevel(double zoomLevel);
  Widget buildPreview();
}
