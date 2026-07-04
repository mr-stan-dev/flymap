import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sky_camera/src/domain/models/sky_camera_capture.dart';
import 'package:sky_camera/src/domain/models/sky_camera_media_format.dart';
import 'package:sky_camera/src/domain/models/sky_camera_overlay_snapshot.dart';
import 'package:sky_camera/src/domain/observers/sky_camera_observer.dart';
import 'package:sky_camera/src/domain/services/sky_camera_driver.dart';
import 'package:sky_camera/src/domain/services/sky_camera_export_service.dart';
import 'package:sky_camera/src/domain/services/sky_camera_overlay_snapshot_source.dart';
import 'package:sky_camera/src/presentation/sky_camera_capture_coordinator.dart';
import 'package:sky_camera/src/presentation/sky_camera_metrics_position.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';
import 'package:sky_camera/src/presentation/sky_camera_zoom_controller.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_bottom_bar.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_close_button.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_error_banner.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_focus_ring.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_gps_loading_badge.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_loading_overlay.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_overlay_view.dart';
import 'package:sky_camera/src/rendering/sky_camera_overlay_composer.dart';
import 'package:sky_camera/src/rendering/sky_camera_photo_cropper.dart';

class SkyCameraScreen extends StatefulWidget {
  const SkyCameraScreen({
    required this.driver,
    required this.snapshotSource,
    required this.exportService,
    required this.observer,
    required this.strings,
    required this.overlayComposer,
    required this.photoCropper,
    required this.openCapturePreview,
    super.key,
  });

  final SkyCameraDriver driver;
  final SkyCameraOverlaySnapshotSource snapshotSource;
  final SkyCameraExportService exportService;
  final SkyCameraObserver observer;
  final SkyCameraStrings strings;
  final SkyCameraOverlayComposer overlayComposer;
  final SkyCameraPhotoCropper photoCropper;
  final Future<Set<String>> Function(
    BuildContext context,
    List<SkyCameraSavedCapture> captures,
    String initialCaptureId,
  )
  openCapturePreview;

  @override
  State<SkyCameraScreen> createState() => _SkyCameraScreenState();
}

class _SkyCameraScreenState extends State<SkyCameraScreen>
    with WidgetsBindingObserver {
  final SkyCameraZoomController _zoomController = SkyCameraZoomController();
  StreamSubscription<SkyCameraOverlaySnapshot>? _snapshotSubscription;
  SkyCameraOverlaySnapshot? _snapshot;
  bool _isCameraLoading = true;
  bool _isGpsLoading = true;
  bool _isCapturing = false;
  String? _errorMessage;
  SkyCameraSavedCapture? _lastCapture;
  final List<SkyCameraSavedCapture> _sessionCaptures = [];
  Offset? _focusPoint;
  bool _didLogOpened = false;
  int _pointers = 0;
  SkyCameraMetricsPosition _metricsPosition = SkyCameraMetricsPosition.initial;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_snapshotSubscription?.cancel());
    unawaited(widget.snapshotSource.dispose());
    unawaited(widget.driver.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_handleAppLifecycleStateChanged(state));
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: _buildMediaViewport(snapshot)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  const Spacer(),
                  if (_errorMessage != null)
                    SkyCameraErrorBanner(message: _errorMessage!),
                  const SizedBox(height: 12),
                  SkyCameraBottomBar(
                    isCapturing: _isCapturing,
                    thumbnailPath: _lastCapture?.overlayPath,
                    onThumbnailTap: _lastCapture == null
                        ? null
                        : _openLastCapturePreview,
                    zoomLevels: _zoomController.presets(),
                    currentZoomLevel: _zoomController.currentZoomLevel,
                    onZoomSelected: _selectZoom,
                    onCapture:
                        _isCameraLoading ||
                            _isCapturing ||
                            !widget.driver.isInitialized
                        ? null
                        : _capture,
                  ),
                ],
              ),
            ),
          ),
          SkyCameraCloseButton(label: widget.strings.close, onPressed: _close),
          if (_isGpsLoading && widget.driver.isInitialized)
            SkyCameraGpsLoadingBadge(label: widget.strings.loadingGpsData),
          if (_isCameraLoading)
            SkyCameraLoadingOverlay(strings: widget.strings),
        ],
      ),
    );
  }

  Widget _buildMediaViewport(SkyCameraOverlaySnapshot? snapshot) {
    return AspectRatio(
      key: const Key('sky_camera.viewport'),
      aspectRatio: SkyCameraMediaFormat.portraitAspectRatio,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.driver.isInitialized)
              Listener(
                onPointerDown: (_) => _pointers += 1,
                onPointerUp: (_) =>
                    _pointers = _pointers > 0 ? _pointers - 1 : 0,
                onPointerCancel: (_) =>
                    _pointers = _pointers > 0 ? _pointers - 1 : 0,
                child: Builder(
                  builder: (previewContext) => GestureDetector(
                    key: const Key('sky_camera.preview_gesture_area'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _handlePreviewTap(previewContext, details),
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    child: widget.driver.buildPreview(),
                  ),
                ),
              )
            else
              _buildFallbackBackground(),
            if (snapshot != null)
              SkyCameraOverlayView(
                snapshot: snapshot,
                strings: widget.strings,
                metricsPosition: _metricsPosition,
                onMetricsPositionChanged: (position) {
                  setState(() => _metricsPosition = position);
                },
              ),
            if (_focusPoint != null)
              SkyCameraFocusRing(
                focusPoint: _focusPoint!,
                onFinished: () {
                  if (!mounted) return;
                  setState(() => _focusPoint = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _initialize() async {
    setState(() {
      _isCameraLoading = true;
      _isGpsLoading = true;
      _errorMessage = null;
    });
    try {
      _snapshotSubscription = widget.snapshotSource.watch().listen((snapshot) {
        if (!mounted) return;
        setState(() {
          _snapshot = snapshot;
          if (snapshot.hasLiveLocation) {
            _isGpsLoading = false;
          }
        });
        if (_didLogOpened) return;
        _didLogOpened = true;
        unawaited(widget.observer.onOpened(snapshot: snapshot));
      });
      unawaited(_startSnapshotSource());
      await widget.driver.initialize();
      await _loadCameraCapabilities();
      if (!mounted) return;
      setState(() => _isCameraLoading = false);
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
        _errorMessage = error.code == 'CameraAccessDenied'
            ? widget.strings.cameraPermissionDenied
            : widget.strings.cameraUnavailable;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
        _errorMessage = widget.strings.cameraUnavailable;
      });
    }
  }

  Future<void> _startSnapshotSource() async {
    try {
      await widget.snapshotSource.start();
    } catch (_) {
      // Keep the camera usable even if GPS bootstrapping fails.
    } finally {
      if (mounted) {
        setState(() => _isGpsLoading = false);
      }
    }
  }

  Future<void> _handleAppLifecycleStateChanged(AppLifecycleState state) async {
    await widget.driver.onAppLifecycleStateChanged(state);
    if (!mounted || state != AppLifecycleState.resumed) return;
    await _loadCameraCapabilities();
  }

  Future<void> _capture() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final metricsPosition = _metricsPosition;
    final captureCoordinator = SkyCameraCaptureCoordinator(
      driver: widget.driver,
      observer: widget.observer,
      exportService: widget.exportService,
      overlayComposer: widget.overlayComposer,
      photoCropper: widget.photoCropper,
      strings: widget.strings,
    );
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });
    try {
      final saved = await captureCoordinator.capture(
        snapshot: snapshot,
        metricsPosition: metricsPosition,
      );
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _sessionCaptures.add(saved);
        _lastCapture = saved;
      });
    } catch (error, stackTrace) {
      debugPrint('SkyCamera capture failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage = widget.strings.captureFailed;
      });
    }
  }

  Future<void> _openLastCapturePreview() async {
    final capture = _lastCapture;
    if (capture == null || !mounted) return;
    final deletedCaptureIds = await widget.openCapturePreview(
      context,
      List<SkyCameraSavedCapture>.unmodifiable(_sessionCaptures),
      capture.id,
    );
    if (deletedCaptureIds.isEmpty || !mounted) return;
    setState(() {
      _sessionCaptures.removeWhere(
        (capture) => deletedCaptureIds.contains(capture.id),
      );
      _lastCapture = _sessionCaptures.isEmpty ? null : _sessionCaptures.last;
    });
  }

  void _close() {
    Navigator.of(context).maybePop();
  }

  Future<void> _handlePreviewTap(
    BuildContext context,
    TapUpDetails details,
  ) async {
    if (!widget.driver.isInitialized) return;
    if (_zoomController.shouldIgnoreTap(DateTime.now())) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPoint = details.localPosition;
    final normalized = Offset(
      (localPoint.dx / box.size.width).clamp(0.0, 1.0),
      (localPoint.dy / box.size.height).clamp(0.0, 1.0),
    );
    setState(() => _focusPoint = localPoint);
    await widget.driver.setFocusPoint(normalized);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomController.handleScaleStart();
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (!widget.driver.isInitialized) return;
    final didChange = await _zoomController.handleScaleUpdate(
      driver: widget.driver,
      pointers: _pointers,
      scale: details.scale,
      now: DateTime.now(),
    );
    if (!didChange || !mounted) return;
    setState(() {});
  }

  Future<void> _selectZoom(double zoomLevel) async {
    if (!widget.driver.isInitialized) return;
    final didChange = await _zoomController.setZoomLevel(
      driver: widget.driver,
      zoomLevel: zoomLevel,
      now: DateTime.now(),
    );
    if (!didChange || !mounted) return;
    setState(() {});
  }

  Future<void> _loadCameraCapabilities() async {
    await _zoomController.loadBounds(widget.driver);
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildFallbackBackground() {
    return Container(
      color: const Color(0xFF06090F),
      alignment: Alignment.center,
      child: const SizedBox.expand(),
    );
  }
}
