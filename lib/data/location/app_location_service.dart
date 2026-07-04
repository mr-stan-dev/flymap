import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flymap/data/location/app_location_client.dart';
import 'package:geolocator/geolocator.dart';

enum AppLocationMode { camera, flight }

enum AppLocationAvailability { available, serviceDisabled, permissionDenied }

class AppLocationSession {
  AppLocationSession._({
    required AppLocationService service,
    required this.availability,
    required int? sessionId,
  }) : _service = service,
       _sessionId = sessionId;

  final AppLocationService _service;
  final int? _sessionId;
  final AppLocationAvailability availability;
  bool _isClosed = false;

  Position? get latestPosition => _service.latestPosition;

  Stream<Position> watch() => _service.watch();

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    final sessionId = _sessionId;
    if (sessionId == null) return;
    await _service._releaseSession(sessionId);
  }
}

class AppLocationService with WidgetsBindingObserver {
  AppLocationService({required AppLocationClient client}) : _client = client;

  static const _streamRetryDelay = Duration(seconds: 1);
  static const freshPositionMaxAge = Duration(seconds: 20);

  final AppLocationClient _client;
  final StreamController<Position> _controller =
      StreamController<Position>.broadcast();
  final Map<int, AppLocationMode> _activeSessions = {};

  StreamSubscription<Position>? _subscription;
  Timer? _recoveryTimer;
  Position? _latestPosition;
  bool _isInitialized = false;
  bool _isForeground = true;
  int _nextSessionId = 0;
  Future<void> _operation = Future<void>.value();

  Position? get latestPosition {
    final position = _latestPosition;
    return position != null && _isFresh(position) ? position : null;
  }

  Stream<Position> watch() => _controller.stream;

  Future<void> initializeForegroundWarmup() async {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
    await warmUpIfPermitted();
  }

  Future<void> warmUpIfPermitted() async {
    await _runOperation(() async {
      if (_activeSessions.isNotEmpty) {
        await _ensureEffectiveStream();
        return;
      }
      await _seedCurrentPositionIfPermitted();
    });
  }

  Future<AppLocationSession> startSession({
    required AppLocationMode mode,
    required bool requestPermission,
  }) async {
    late AppLocationSession session;
    await _runOperation(() async {
      final serviceEnabled = await _client.isLocationServiceEnabled();
      if (!serviceEnabled) {
        session = AppLocationSession._(
          service: this,
          availability: AppLocationAvailability.serviceDisabled,
          sessionId: null,
        );
        return;
      }

      var permission = await _client.checkPermission();
      if (requestPermission && permission == LocationPermission.denied) {
        permission = await _client.requestPermission();
      }
      if (!_isGranted(permission)) {
        session = AppLocationSession._(
          service: this,
          availability: AppLocationAvailability.permissionDenied,
          sessionId: null,
        );
        return;
      }

      final sessionId = _nextSessionId++;
      _activeSessions[sessionId] = mode;
      await _ensureEffectiveStream();
      session = AppLocationSession._(
        service: this,
        availability: AppLocationAvailability.available,
        sessionId: sessionId,
      );
    });
    return session;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      unawaited(warmUpIfPermitted());
      return;
    }
    unawaited(_runOperation(_stopStream));
  }

  Future<void> _releaseSession(int sessionId) async {
    await _runOperation(() async {
      _activeSessions.remove(sessionId);
      if (_activeSessions.isEmpty) {
        await _ensureEffectiveStream();
      }
    });
  }

  Future<void> _seedCurrentPositionIfPermitted() async {
    final serviceEnabled = await _client.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    final permission = await _client.checkPermission();
    if (!_isGranted(permission)) return;
    unawaited(_publishCurrentPosition(LocationAccuracy.medium));
  }

  Future<void> _ensureEffectiveStream() async {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
    if (!_isForeground || _activeSessions.isEmpty) {
      await _stopStream();
      return;
    }
    if (_subscription != null) {
      return;
    }

    await _stopStream();
    try {
      _subscription = _client
          .getPositionStream(locationSettings: _navigationLocationSettings())
          .listen(_publish, onError: _handleStreamError);
    } catch (error, stackTrace) {
      _controller.addError(error, stackTrace);
      _scheduleStreamRecovery();
      return;
    }
    unawaited(_publishCurrentPosition(LocationAccuracy.bestForNavigation));
  }

  Future<void> _publishCurrentPosition(LocationAccuracy accuracy) async {
    try {
      final current = await _client.getCurrentPosition(accuracy: accuracy);
      _publish(current);
    } catch (_) {
      // The continuous stream remains the source of truth.
    }
  }

  Future<void> _stopStream() async {
    final subscription = _subscription;
    _subscription = null;
    if (subscription == null) return;
    await subscription.cancel();
  }

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (!_controller.isClosed) {
      _controller.addError(error, stackTrace);
    }
    _scheduleStreamRecovery();
  }

  void _scheduleStreamRecovery() {
    if (_recoveryTimer != null) return;
    unawaited(_runOperation(_stopStream));
    _recoveryTimer = Timer(_streamRetryDelay, () {
      _recoveryTimer = null;
      if (!_isForeground || _activeSessions.isEmpty) return;
      unawaited(_runOperation(_ensureEffectiveStream));
    });
  }

  void _publish(Position position) {
    if (!_isFresh(position)) return;
    final latestTimestamp = _latestPosition?.timestamp;
    if (latestTimestamp != null &&
        position.timestamp.isBefore(latestTimestamp)) {
      return;
    }
    _latestPosition = position;
    if (_controller.isClosed) return;
    _controller.add(position);
  }

  bool _isFresh(Position position) {
    final age = DateTime.now().difference(position.timestamp);
    return age >= -freshPositionMaxAge && age <= freshPositionMaxAge;
  }

  LocationSettings _navigationLocationSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
          useMSLAltitude: true,
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          activityType: ActivityType.airborne,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        );
    }
  }

  bool _isGranted(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _runOperation(Future<void> Function() action) {
    final next = _operation.then((_) => action());
    _operation = next.catchError((_) {});
    return next;
  }
}
