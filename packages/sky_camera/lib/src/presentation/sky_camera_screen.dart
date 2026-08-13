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
import 'package:sky_camera/src/domain/services/sky_camera_resource_monitor.dart';
import 'package:sky_camera/src/presentation/sky_camera_capture_coordinator.dart';
import 'package:sky_camera/src/presentation/sky_camera_metrics_position.dart';
import 'package:sky_camera/src/presentation/sky_camera_strings.dart';
import 'package:sky_camera/src/presentation/sky_camera_video_track_recorder.dart';
import 'package:sky_camera/src/presentation/sky_camera_zoom_controller.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_bottom_bar.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_close_button.dart';
import 'package:sky_camera/src/presentation/widgets/sky_camera_settings_sheet.dart';
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
    this.onRecordAudioChanged,
    this.resourceMonitor,
    this.resourceCheckInterval = const Duration(seconds: 2),
    this.videoCaptureEnabled = true,
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

  /// Persists the record-audio preference after the driver applied it.
  final ValueChanged<bool>? onRecordAudioChanged;

  /// Resource pressure is sampled before and during video recording. A
  /// reported issue stops and saves the current clip.
  final SkyCameraResourceMonitor? resourceMonitor;
  final Duration resourceCheckInterval;

  /// When false the camera is photo-only: the capture-mode switch is hidden
  /// and video recording can never start (release feature gate).
  final bool videoCaptureEnabled;

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
  SkyCameraCaptureMode _captureMode = SkyCameraCaptureMode.photo;
  final SkyCameraVideoTrackRecorder _trackRecorder =
      SkyCameraVideoTrackRecorder();
  bool _isStartingVideo = false;
  bool _isRecordingVideo = false;
  bool _isStoppingVideo = false;
  bool _isClosing = false;
  bool _allowPop = false;
  Future<void>? _startingVideoOperation;
  Future<void>? _stoppingVideoOperation;

  /// Advanced by the one-second ticker so the chip and shutter countdown
  /// share one clock with the auto-stop timer.
  Duration _recordingElapsed = Duration.zero;
  Timer? _recordingTicker;
  Timer? _recordingAutoStop;
  Timer? _recordingResourceTimer;
  bool _isCheckingRecordingResources = false;
  SkyCameraRecordingResourceIssue? _resourceStopIssue;
  Future<void> _lifecycleOperation = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initialize());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordingTicker?.cancel();
    _recordingAutoStop?.cancel();
    _recordingResourceTimer?.cancel();
    unawaited(_snapshotSubscription?.cancel());
    unawaited(widget.snapshotSource.dispose());
    unawaited(widget.driver.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Preserve the order delivered by Flutter. Stopping and saving a video can
    // outlive a quick trip through the app switcher; without a queue, the
    // resumed handler can initialize first and the older paused handler then
    // disposes the camera after the user has already returned.
    _lifecycleOperation = _lifecycleOperation
        .then((_) => _handleAppLifecycleStateChanged(state))
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('SkyCamera lifecycle transition failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        });
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_close());
      },
      child: Scaffold(
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
                      captureMode: _captureMode,
                      isRecording: _isRecordingVideo,
                      isTransitioning: _isStartingVideo || _isClosing,
                      recordingElapsed: _isRecordingVideo
                          ? _recordingElapsed
                          : null,
                      maxRecordingDuration:
                          SkyCameraMediaFormat.maxVideoDuration,
                      onCaptureModeChanged: !widget.videoCaptureEnabled
                          ? null
                          : (mode) {
                              if (_isStartingVideo ||
                                  _isRecordingVideo ||
                                  _isCapturing ||
                                  _isClosing) {
                                return;
                              }
                              setState(() => _captureMode = mode);
                            },
                      onCapture:
                          _isCameraLoading ||
                              _isStartingVideo ||
                              _isCapturing ||
                              _isClosing ||
                              !widget.driver.isInitialized
                          ? null
                          : _capture,
                    ),
                  ],
                ),
              ),
            ),
            SkyCameraCloseButton(
              label: widget.strings.close,
              onPressed: _close,
            ),
            if (!_isStartingVideo &&
                !_isRecordingVideo &&
                !_isCapturing &&
                !_isClosing)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 12),
                    child: Material(
                      color: const Color(0xAA161A20),
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: const Key('sky_camera.settings_button'),
                        onPressed: _openSettings,
                        tooltip: widget.strings.settingsTitle,
                        iconSize: 22,
                        padding: const EdgeInsets.all(12),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 22,
                        color: Colors.white,
                        icon: const Icon(Icons.tune_rounded),
                      ),
                    ),
                  ),
                ),
              ),
            if (_isRecordingVideo)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _SkyCameraRecordingChip(
                      elapsed: _recordingElapsed,
                      maxDuration: SkyCameraMediaFormat.maxVideoDuration,
                    ),
                  ),
                ),
              ),
            if (_isGpsLoading && widget.driver.isInitialized)
              SkyCameraGpsLoadingBadge(label: widget.strings.loadingGpsData),
            if (_isCameraLoading)
              SkyCameraLoadingOverlay(strings: widget.strings),
          ],
        ),
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
        if (_isRecordingVideo) {
          _trackRecorder.addSnapshot(snapshot, at: DateTime.now());
        }
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
      if (!mounted) return;
      setState(() => _isCameraLoading = false);
      await _loadCameraCapabilities();
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
    if (state == AppLifecycleState.paused) {
      // Backgrounding kills the capture session — stop and SAVE what was
      // recorded instead of discarding it. Let an in-flight start settle
      // first; the driver's lifecycle queue guarantees its dispose runs
      // after the stop below.
      await _startingVideoOperation;
      if (_isRecordingVideo) {
        await _stopVideoRecording();
      }
    }
    try {
      await widget.driver.onAppLifecycleStateChanged(state);
    } on CameraException catch (error) {
      if (!mounted || widget.driver.isInitialized) return;
      setState(() {
        _isCameraLoading = false;
        _errorMessage = error.code == 'CameraAccessDenied'
            ? widget.strings.cameraPermissionDenied
            : widget.strings.cameraUnavailable;
      });
      return;
    } catch (_) {
      if (!mounted || widget.driver.isInitialized) return;
      setState(() {
        _isCameraLoading = false;
        _errorMessage = widget.strings.cameraUnavailable;
      });
      return;
    }
    if (!mounted || state != AppLifecycleState.resumed) return;
    await _loadCameraCapabilities();
  }

  SkyCameraCaptureCoordinator _buildCoordinator() {
    return SkyCameraCaptureCoordinator(
      driver: widget.driver,
      observer: widget.observer,
      exportService: widget.exportService,
      overlayComposer: widget.overlayComposer,
      photoCropper: widget.photoCropper,
      strings: widget.strings,
    );
  }

  Future<void> _capture() async {
    if (_captureMode == SkyCameraCaptureMode.video) {
      if (_isRecordingVideo) {
        await _stopVideoRecording();
      } else {
        await _startVideoRecording();
      }
      return;
    }
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final metricsPosition = _metricsPosition;
    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });
    try {
      final saved = await _buildCoordinator().capture(
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

  Future<void> _startVideoRecording() {
    final activeOperation = _startingVideoOperation;
    if (activeOperation != null) return activeOperation;
    late final Future<void> operation;
    operation = _performStartVideoRecording().whenComplete(() {
      if (identical(_startingVideoOperation, operation)) {
        _startingVideoOperation = null;
      }
    });
    _startingVideoOperation = operation;
    return operation;
  }

  Future<void> _performStartVideoRecording() async {
    final snapshot = _snapshot;
    if (snapshot == null ||
        _isStartingVideo ||
        _isRecordingVideo ||
        _isStoppingVideo ||
        _isClosing) {
      return;
    }
    setState(() {
      _isStartingVideo = true;
      _errorMessage = null;
    });
    final resourceIssue = await _currentRecordingResourceIssue();
    if (!mounted) return;
    if (resourceIssue != null) {
      setState(() {
        _isStartingVideo = false;
        _errorMessage = _resourceIssueMessage(resourceIssue, stopped: false);
      });
      return;
    }
    try {
      await widget.driver.startVideoRecording();
    } catch (error) {
      debugPrint('SkyCamera video start failed: $error');
      if (!mounted) return;
      setState(() {
        _isStartingVideo = false;
        _errorMessage = widget.strings.captureFailed;
      });
      return;
    }
    if (!mounted) return;
    final startedAt = DateTime.now();
    _trackRecorder.start(startedAt: startedAt);
    _trackRecorder.addSnapshot(snapshot, at: startedAt);
    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recordingElapsed += const Duration(seconds: 1);
      });
    });
    _recordingAutoStop = Timer(
      SkyCameraMediaFormat.maxVideoDuration,
      () => unawaited(_stopVideoRecording()),
    );
    final resourceCheckInterval = widget.resourceCheckInterval;
    if (widget.resourceMonitor != null &&
        resourceCheckInterval > Duration.zero) {
      _recordingResourceTimer = Timer.periodic(
        resourceCheckInterval,
        (_) => unawaited(_checkRecordingResources()),
      );
    }
    setState(() {
      _isStartingVideo = false;
      _isRecordingVideo = true;
      _recordingElapsed = Duration.zero;
    });
  }

  Future<void> _stopVideoRecording() {
    final activeOperation = _stoppingVideoOperation;
    if (activeOperation != null) return activeOperation;
    late final Future<void> operation;
    operation = _performStopVideoRecording().whenComplete(() {
      if (identical(_stoppingVideoOperation, operation)) {
        _stoppingVideoOperation = null;
      }
    });
    _stoppingVideoOperation = operation;
    return operation;
  }

  Future<void> _performStopVideoRecording() async {
    if (!_isRecordingVideo || _isStoppingVideo) return;
    _isStoppingVideo = true;
    _recordingTicker?.cancel();
    _recordingAutoStop?.cancel();
    _recordingResourceTimer?.cancel();
    _recordingResourceTimer = null;
    final track = _trackRecorder.stop();
    final snapshot = track.isNotEmpty ? track.first.snapshot : _snapshot;
    final resourceStopIssue = _resourceStopIssue;
    setState(() {
      _isRecordingVideo = false;
      _isCapturing = true;
    });
    try {
      final saved = await _buildCoordinator().finishVideoCapture(
        snapshot: snapshot!,
        track: track,
      );
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _sessionCaptures.add(saved);
        _lastCapture = saved;
        if (resourceStopIssue != null) {
          _errorMessage = _resourceIssueMessage(
            resourceStopIssue,
            stopped: true,
          );
        }
      });
    } catch (error, stackTrace) {
      debugPrint('SkyCamera video capture failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage = widget.strings.captureFailed;
      });
    } finally {
      _isStoppingVideo = false;
      if (_resourceStopIssue == resourceStopIssue) {
        _resourceStopIssue = null;
      }
    }
  }

  Future<SkyCameraRecordingResourceIssue?>
  _currentRecordingResourceIssue() async {
    final monitor = widget.resourceMonitor;
    if (monitor == null) return null;
    try {
      return await monitor.currentIssue();
    } catch (error) {
      debugPrint('SkyCamera resource check failed: $error');
      return null;
    }
  }

  Future<void> _checkRecordingResources() async {
    if (_isCheckingRecordingResources ||
        !_isRecordingVideo ||
        _isStoppingVideo) {
      return;
    }
    _isCheckingRecordingResources = true;
    try {
      final issue = await _currentRecordingResourceIssue();
      if (!mounted || issue == null || !_isRecordingVideo || _isStoppingVideo) {
        return;
      }
      _resourceStopIssue = issue;
      await _stopVideoRecording();
    } finally {
      _isCheckingRecordingResources = false;
    }
  }

  String _resourceIssueMessage(
    SkyCameraRecordingResourceIssue issue, {
    required bool stopped,
  }) {
    return switch (issue) {
      SkyCameraRecordingResourceIssue.lowStorage =>
        stopped
            ? widget.strings.lowStorageRecordingStopped
            : widget.strings.lowStorageRecordingBlocked,
      SkyCameraRecordingResourceIssue.deviceTooHot =>
        stopped
            ? widget.strings.hotDeviceRecordingStopped
            : widget.strings.hotDeviceRecordingBlocked,
    };
  }

  Future<void> _openSettings() async {
    if (_isStartingVideo || _isRecordingVideo || _isCapturing || _isClosing) {
      return;
    }
    await showSkyCameraSettingsSheet(
      context,
      strings: widget.strings,
      audioEnabled: widget.driver.isAudioEnabled,
      onRecordAudioChanged: _applyRecordAudio,
    );
  }

  Future<bool> _applyRecordAudio(bool enabled) async {
    try {
      await widget.driver.setAudioEnabled(enabled);
    } catch (_) {
      // Microphone denied (or re-init failed): the driver fell back to a
      // silent camera; tell the user why the switch snapped back.
      if (mounted) {
        setState(
          () => _errorMessage = widget.strings.microphonePermissionDenied,
        );
      }
      widget.onRecordAudioChanged?.call(widget.driver.isAudioEnabled);
      return widget.driver.isAudioEnabled;
    }
    widget.onRecordAudioChanged?.call(enabled);
    if (mounted) setState(() {});
    return enabled;
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

  Future<void> _close() async {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    try {
      await _startingVideoOperation;
      if (_isRecordingVideo) {
        await _stopVideoRecording();
      } else {
        await _stoppingVideoOperation;
      }
      if (!mounted) return;
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final didPop = await Navigator.of(context).maybePop();
      if (!didPop && mounted) {
        setState(() => _allowPop = false);
      }
    } finally {
      if (mounted) _isClosing = false;
    }
  }

  Future<void> _handlePreviewTap(
    BuildContext context,
    TapUpDetails details,
  ) async {
    if (!widget.driver.isInitialized || _isStartingVideo || _isClosing) return;
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
    if (_isStartingVideo || _isClosing) return;
    _zoomController.handleScaleStart();
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (!widget.driver.isInitialized || _isStartingVideo || _isClosing) return;
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
    if (!widget.driver.isInitialized || _isStartingVideo || _isClosing) return;
    final didChange = await _zoomController.setZoomLevel(
      driver: widget.driver,
      zoomLevel: zoomLevel,
      now: DateTime.now(),
    );
    if (!didChange || !mounted) return;
    setState(() {});
  }

  Future<void> _loadCameraCapabilities() async {
    try {
      await _zoomController.loadBounds(widget.driver);
    } catch (_) {
      // Zoom discovery is optional; preview and capture remain usable.
      return;
    }
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

/// "● 0:07 / 0:30" pill shown while a video is recording. Driven by the
/// screen's one-second ticker.
class _SkyCameraRecordingChip extends StatelessWidget {
  const _SkyCameraRecordingChip({
    required this.elapsed,
    required this.maxDuration,
  });

  final Duration elapsed;
  final Duration maxDuration;

  @override
  Widget build(BuildContext context) {
    final clamped = elapsed > maxDuration ? maxDuration : elapsed;
    return Container(
      key: const Key('sky_camera.recording_chip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xAA161A20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_format(clamped)} / ${_format(maxDuration)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
