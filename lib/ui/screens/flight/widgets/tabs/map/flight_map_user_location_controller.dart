import 'dart:async';
import 'dart:math' as math;

import 'package:flymap/domain/entity/gps_data.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/user_layer.dart';
import 'package:flymap/ui/map/map_style_safety.dart';
import 'package:flymap/utils/speed_unit_utils.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapUserLocationController {
  FlightMapUserLocationController({required Logger logger}) : _logger = logger;

  static const _planeImageId = 'flight-map-user-plane';
  static const _estimatedPlaneImageId = 'flight-map-user-plane-estimated';
  static const _planeSourceId = 'flight-map-user-plane-source';
  static const _planeLayerId = 'flight-map-user-plane-layer';
  static const _planeIconAssetPath = 'assets/images/icons/plane_blue.png';
  static const _estimatedPlaneIconAssetPath =
      'assets/images/icons/plane_gray.png';
  static const _stationarySpeedThresholdMetersPerSecond = 4.0;
  static const _defaultAnimationDuration = Duration(milliseconds: 1200);
  static const _minAnimationDuration = Duration(milliseconds: 350);
  static const _maxAnimationDuration = Duration(milliseconds: 2200);
  static const _frameInterval = Duration(milliseconds: 100);

  final Logger _logger;
  final Map<String, Uint8List> _assetBytesCache = {};

  Circle? _userCircle;
  _UserLocationUpdate? _pendingUpdate;
  bool _isApplyingUserLocation = false;
  bool _isPlaneLayerReady = false;
  LatLng? _renderedPosition;
  double _renderedHeading = 0;
  DateTime? _lastAppliedFixAt;
  int _animationGeneration = 0;

  LatLng? get currentUserLocation => _renderedPosition;
  double get currentUserHeading => _renderedHeading;

  Future<void> updateUserLocation(
    GpsData data, {
    bool approximate = false,
    required MapLibreMapController? controller,
    required bool Function() isReady,
    required bool Function() shouldFollowUser,
    required bool Function() shouldFollowHeadingUp,
    required double Function() followZoomProvider,
    required double Function() followTiltProvider,
  }) async {
    _pendingUpdate = _UserLocationUpdate(data: data, approximate: approximate);

    if (controller == null || !isReady()) return;
    if (_isApplyingUserLocation) return;

    _isApplyingUserLocation = true;
    try {
      while (_pendingUpdate != null) {
        final next = _pendingUpdate!;
        _pendingUpdate = null;
        await _applyUserLocation(
          next.data,
          approximate: next.approximate,
          controller: controller,
          isReady: isReady,
          shouldFollowUser: shouldFollowUser,
          shouldFollowHeadingUp: shouldFollowHeadingUp,
          followZoomProvider: followZoomProvider,
          followTiltProvider: followTiltProvider,
        );
      }
    } finally {
      _isApplyingUserLocation = false;
    }
  }

  Future<void> _applyUserLocation(
    GpsData data, {
    required bool approximate,
    required MapLibreMapController controller,
    required bool Function() isReady,
    required bool Function() shouldFollowUser,
    required bool Function() shouldFollowHeadingUp,
    required double Function() followZoomProvider,
    required double Function() followTiltProvider,
  }) async {
    if (!isReady()) return;
    final lat = data.latitude;
    final lon = data.longitude;
    _logger.log('updateUserLocation lat: $lat, lon: $lon');
    if (lat == null || lon == null) return;
    final pos = LatLng(lat, lon);
    final heading = _resolveHeading(
      targetPosition: pos,
      fallbackHeading: data.course ?? _renderedHeading,
    );
    final showCircle = _shouldShowStationaryCircle(data.speed);
    var createdCircle = false;

    try {
      if (_userCircle == null) {
        _userCircle = await controller.addCircle(
          UserLayer.markerCircle(
            pos,
            visible: showCircle,
            approximate: approximate,
          ),
        );
        createdCircle = true;
      } else {
        final reachedTarget = await _animateMarkerTransition(
          controller: controller,
          targetPosition: pos,
          targetHeading: heading,
          shouldFollowUser: shouldFollowUser,
          shouldFollowHeadingUp: shouldFollowHeadingUp,
          followZoomProvider: followZoomProvider,
          followTiltProvider: followTiltProvider,
          showCircle: showCircle,
          approximate: approximate,
        );
        if (!reachedTarget) {
          return;
        }
      }

      if (createdCircle || _renderedPosition == null) {
        await _updateRenderedMarker(
          controller: controller,
          position: pos,
          heading: heading,
          showCircle: showCircle,
          approximate: approximate,
        );
      }
    } catch (error) {
      _logger.error('Failed to apply user location marker: $error');
      if (_isStyleBoundAnnotationError(error)) {
        invalidateStyle(keepRenderedPosition: true);
      }
      _pendingUpdate = _UserLocationUpdate(
        data: data,
        approximate: approximate,
      );
      if (isReady()) {
        Future.delayed(const Duration(milliseconds: 250), () {
          final pending = _pendingUpdate;
          if (pending != null && isReady()) {
            unawaited(
              updateUserLocation(
                pending.data,
                approximate: pending.approximate,
                controller: controller,
                isReady: isReady,
                shouldFollowUser: shouldFollowUser,
                shouldFollowHeadingUp: shouldFollowHeadingUp,
                followZoomProvider: followZoomProvider,
                followTiltProvider: followTiltProvider,
              ),
            );
          }
        });
      }
      return;
    }

    if (shouldFollowUser()) {
      await _moveFollowCamera(
        controller: controller,
        position: pos,
        heading: heading,
        followHeadingUp: shouldFollowHeadingUp(),
        followZoom: followZoomProvider(),
        followTilt: followTiltProvider(),
      );
    }
  }

  Future<bool> _animateMarkerTransition({
    required MapLibreMapController controller,
    required LatLng targetPosition,
    required double targetHeading,
    required bool Function() shouldFollowUser,
    required bool Function() shouldFollowHeadingUp,
    required double Function() followZoomProvider,
    required double Function() followTiltProvider,
    required bool showCircle,
    required bool approximate,
  }) async {
    final startPosition = _renderedPosition ?? targetPosition;
    final startHeading = _renderedHeading;
    final now = DateTime.now();
    final animationDuration = _resolveAnimationDuration(now);
    _lastAppliedFixAt = now;

    if (_shouldSkipInterpolation(startPosition, targetPosition)) {
      await _updateRenderedMarker(
        controller: controller,
        position: targetPosition,
        heading: targetHeading,
        showCircle: showCircle,
        approximate: approximate,
      );
      if (shouldFollowUser()) {
        await _moveFollowCamera(
          controller: controller,
          position: targetPosition,
          heading: targetHeading,
          followHeadingUp: shouldFollowHeadingUp(),
          followZoom: followZoomProvider(),
          followTilt: followTiltProvider(),
        );
      }
      return true;
    }

    final generation = ++_animationGeneration;
    final totalFrames =
        (animationDuration.inMilliseconds / _frameInterval.inMilliseconds)
            .ceil()
            .clamp(1, 24);
    var previousFramePosition = startPosition;
    for (var frame = 1; frame <= totalFrames; frame++) {
      if (generation != _animationGeneration) return false;
      if (_pendingUpdate != null) {
        await _updateRenderedMarker(
          controller: controller,
          position: targetPosition,
          heading: targetHeading,
          showCircle: showCircle,
          approximate: approximate,
        );
        if (shouldFollowUser()) {
          await _moveFollowCamera(
            controller: controller,
            position: targetPosition,
            heading: targetHeading,
            followHeadingUp: shouldFollowHeadingUp(),
            followZoom: followZoomProvider(),
            followTilt: followTiltProvider(),
          );
        }
        return true;
      }

      final t = frame / totalFrames;
      final position = LatLng(
        startPosition.latitude +
            (targetPosition.latitude - startPosition.latitude) * t,
        _interpolateLongitudeShortestPath(
          startPosition.longitude,
          targetPosition.longitude,
          t,
        ),
      );
      final interpolatedHeading = _interpolateHeadingShortestPath(
        startHeading,
        targetHeading,
        t,
      );
      final heading = _headingFromMovement(
        from: previousFramePosition,
        to: position,
        fallbackHeading: interpolatedHeading,
      );
      previousFramePosition = position;
      await _updateRenderedMarker(
        controller: controller,
        position: position,
        heading: heading,
        showCircle: showCircle,
        approximate: approximate,
      );
      if (shouldFollowUser()) {
        await _moveFollowCamera(
          controller: controller,
          position: position,
          heading: heading,
          followHeadingUp: shouldFollowHeadingUp(),
          followZoom: followZoomProvider(),
          followTilt: followTiltProvider(),
        );
      }
      if (frame < totalFrames) {
        await Future.delayed(_frameInterval);
      }
    }
    return true;
  }

  Future<void> _moveFollowCamera({
    required MapLibreMapController controller,
    required LatLng position,
    required double heading,
    required bool followHeadingUp,
    required double followZoom,
    required double followTilt,
  }) async {
    if (!followHeadingUp) {
      await controller.moveCamera(CameraUpdate.newLatLng(position));
      return;
    }
    final zoom = followZoom.isFinite ? followZoom : 5.0;
    final tilt = followTilt.isFinite ? followTilt : 0.0;
    await controller.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: zoom,
          tilt: tilt,
          bearing: _normalizeHeading(heading),
        ),
      ),
    );
  }

  Future<void> _updateRenderedMarker({
    required MapLibreMapController controller,
    required LatLng position,
    required double heading,
    required bool showCircle,
    required bool approximate,
  }) async {
    await controller.updateCircle(
      _userCircle!,
      UserLayer.markerCircle(
        position,
        visible: showCircle,
        approximate: approximate,
      ),
    );
    await _updatePlaneLayer(
      controller: controller,
      position: position,
      heading: heading,
      visible: !showCircle,
      approximate: approximate,
    );
    _renderedPosition = position;
    _renderedHeading = heading;
  }

  Future<void> _updatePlaneLayer({
    required MapLibreMapController controller,
    required LatLng position,
    required double heading,
    required bool visible,
    required bool approximate,
  }) async {
    if (!_isPlaneLayerReady) {
      await _rebuildPlaneLayer(
        controller: controller,
        position: position,
        heading: heading,
        visible: visible,
        approximate: approximate,
      );
      return;
    }

    try {
      await controller.setGeoJsonSource(
        _planeSourceId,
        _planeFeatureCollection(
          position: position,
          heading: heading,
          visible: visible,
          approximate: approximate,
        ),
      );
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _isPlaneLayerReady = false;
        return;
      }
      _logger.log('Rebuilding plane layer after source update error: $error');
      await _rebuildPlaneLayer(
        controller: controller,
        position: position,
        heading: heading,
        visible: visible,
        approximate: approximate,
      );
    }
  }

  Future<void> _rebuildPlaneLayer({
    required MapLibreMapController controller,
    required LatLng position,
    required double heading,
    required bool visible,
    required bool approximate,
  }) async {
    await _ensurePlaneImagesRegistered(controller);
    await _removePlaneLayerArtifacts(controller);
    await controller.addGeoJsonSource(
      _planeSourceId,
      _planeFeatureCollection(
        position: position,
        heading: heading,
        visible: visible,
        approximate: approximate,
      ),
    );
    await controller.addLayer(
      _planeSourceId,
      _planeLayerId,
      SymbolLayerProperties(
        iconImage: [
          'case',
          [
            '==',
            ['get', 'approximate'],
            true,
          ],
          _estimatedPlaneImageId,
          _planeImageId,
        ],
        iconSize: 0.52,
        iconRotate: ['get', 'bearing'],
        iconRotationAlignment: 'map',
        iconPitchAlignment: 'map',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconAnchor: 'center',
        iconOpacity: [
          'case',
          [
            '==',
            ['get', 'visible'],
            true,
          ],
          1.0,
          0.0,
        ],
      ),
    );
    _isPlaneLayerReady = true;
  }

  Future<void> _removePlaneLayerArtifacts(
    MapLibreMapController controller,
  ) async {
    try {
      await controller.removeLayer(_planeLayerId);
    } catch (_) {}
    try {
      await controller.removeSource(_planeSourceId);
    } catch (_) {}
  }

  Map<String, dynamic> _planeFeatureCollection({
    required LatLng position,
    required double heading,
    required bool visible,
    required bool approximate,
  }) {
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'Feature',
          'properties': <String, dynamic>{
            'bearing': _normalizeHeading(heading),
            'visible': visible,
            'approximate': approximate,
          },
          'geometry': <String, dynamic>{
            'type': 'Point',
            'coordinates': <double>[position.longitude, position.latitude],
          },
        },
      ],
    };
  }

  bool _shouldShowStationaryCircle(SpeedValue? speed) {
    if (speed == null) return false;
    return SpeedUnitUtils.toMetersPerSecond(speed) <=
        _stationarySpeedThresholdMetersPerSecond;
  }

  Future<void> _ensurePlaneImagesRegistered(
    MapLibreMapController controller,
  ) async {
    await _ensurePlaneImageRegistered(
      controller,
      imageId: _planeImageId,
      assetPath: _planeIconAssetPath,
    );
    await _ensurePlaneImageRegistered(
      controller,
      imageId: _estimatedPlaneImageId,
      assetPath: _estimatedPlaneIconAssetPath,
    );
  }

  Future<void> _ensurePlaneImageRegistered(
    MapLibreMapController controller, {
    required String imageId,
    required String assetPath,
  }) async {
    final bytes = await _loadAssetBytes(assetPath);
    if (bytes == null) return;
    try {
      await controller.addImage(imageId, bytes);
    } catch (error) {
      if (!_isImageAlreadyRegisteredError(error)) {
        _logger.error('Failed to register plane image "$imageId": $error');
      }
    }
  }

  Future<Uint8List?> _loadAssetBytes(String assetPath) async {
    final cached = _assetBytesCache[assetPath];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      _assetBytesCache[assetPath] = bytes;
      return bytes;
    } catch (error) {
      _logger.error('Failed to load asset "$assetPath": $error');
      return null;
    }
  }

  bool _isImageAlreadyRegisteredError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('already exists') ||
        text.contains('image already added') ||
        text.contains('name already exists');
  }

  Duration _resolveAnimationDuration(DateTime now) {
    final previous = _lastAppliedFixAt;
    if (previous == null) {
      return _defaultAnimationDuration;
    }
    final delta = now.difference(previous);
    if (delta <= Duration.zero) {
      return _minAnimationDuration;
    }
    if (delta < _minAnimationDuration) {
      return _minAnimationDuration;
    }
    if (delta > _maxAnimationDuration) {
      return _maxAnimationDuration;
    }
    return delta;
  }

  bool _shouldSkipInterpolation(LatLng start, LatLng target) {
    final latDelta = (target.latitude - start.latitude).abs();
    final lonDelta = (_normalizeLongitude(
      target.longitude - start.longitude,
    )).abs();
    return latDelta < 0.0001 && lonDelta < 0.0001;
  }

  double _interpolateLongitudeShortestPath(
    double fromLon,
    double toLon,
    double t,
  ) {
    var delta = toLon - fromLon;
    if (delta > 180.0) {
      delta -= 360.0;
    } else if (delta < -180.0) {
      delta += 360.0;
    }
    return _normalizeLongitude(fromLon + delta * t);
  }

  double _interpolateHeadingShortestPath(
    double fromHeading,
    double toHeading,
    double t,
  ) {
    final normalizedFrom = _normalizeHeading(fromHeading);
    final normalizedTo = _normalizeHeading(toHeading);
    var delta = normalizedTo - normalizedFrom;
    if (delta > 180.0) {
      delta -= 360.0;
    } else if (delta < -180.0) {
      delta += 360.0;
    }
    return _normalizeHeading(normalizedFrom + delta * t);
  }

  double _resolveHeading({
    required LatLng targetPosition,
    required double fallbackHeading,
  }) {
    final current = _renderedPosition;
    if (current == null) {
      return _normalizeHeading(fallbackHeading);
    }
    return _headingFromMovement(
      from: current,
      to: targetPosition,
      fallbackHeading: fallbackHeading,
    );
  }

  double _headingFromMovement({
    required LatLng from,
    required LatLng to,
    required double fallbackHeading,
  }) {
    final distanceSquared =
        math.pow(to.latitude - from.latitude, 2) +
        math.pow(_normalizeLongitude(to.longitude - from.longitude), 2);
    if (distanceSquared < 1e-10) {
      return _normalizeHeading(fallbackHeading);
    }
    return _bearingDegrees(from, to);
  }

  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(_normalizeLongitude(to.longitude - from.longitude));
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        (math.cos(lat1) * math.sin(lat2)) -
        (math.sin(lat1) * math.cos(lat2) * math.cos(dLon));
    final raw = _radToDeg(math.atan2(y, x));
    return _normalizeHeading(raw);
  }

  double _normalizeLongitude(double longitude) {
    var lon = longitude;
    while (lon > 180.0) {
      lon -= 360.0;
    }
    while (lon < -180.0) {
      lon += 360.0;
    }
    return lon;
  }

  double _normalizeHeading(double heading) {
    final normalized = heading % 360;
    return normalized < 0 ? normalized + 360 : normalized;
  }

  double _degToRad(double value) => value * (math.pi / 180);
  double _radToDeg(double value) => value * (180 / math.pi);

  Future<void> flushPendingGpsData({
    required MapLibreMapController? controller,
    required bool Function() isReady,
    required bool Function() shouldFollowUser,
    required bool Function() shouldFollowHeadingUp,
    required double Function() followZoomProvider,
    required double Function() followTiltProvider,
  }) async {
    final pending = _pendingUpdate;
    if (pending == null) return;
    await updateUserLocation(
      pending.data,
      approximate: pending.approximate,
      controller: controller,
      isReady: isReady,
      shouldFollowUser: shouldFollowUser,
      shouldFollowHeadingUp: shouldFollowHeadingUp,
      followZoomProvider: followZoomProvider,
      followTiltProvider: followTiltProvider,
    );
  }

  Future<void> hideUserLocation({
    required MapLibreMapController? controller,
  }) async {
    _animationGeneration++;
    _pendingUpdate = null;
    final position = _renderedPosition;
    if (controller != null && position != null) {
      try {
        final circle = _userCircle;
        if (circle != null) {
          await controller.updateCircle(
            circle,
            UserLayer.markerCircle(position, visible: false),
          );
        }
        if (_isPlaneLayerReady) {
          await _updatePlaneLayer(
            controller: controller,
            position: position,
            heading: _renderedHeading,
            visible: false,
            approximate: true,
          );
        }
      } catch (error) {
        _logger.error('Failed to hide user location marker: $error');
      }
    }
    _renderedPosition = null;
    _renderedHeading = 0;
    _lastAppliedFixAt = null;
  }

  void invalidateStyle({bool keepRenderedPosition = true}) {
    _animationGeneration++;
    _userCircle = null;
    _isApplyingUserLocation = false;
    _isPlaneLayerReady = false;
    if (!keepRenderedPosition) {
      _renderedPosition = null;
      _renderedHeading = 0;
      _lastAppliedFixAt = null;
    }
  }

  bool _isStyleBoundAnnotationError(Object error) {
    final message = error.toString();
    return message.contains('you can only set existing annotations') ||
        message.contains('This Annotation Manager has not been initialized');
  }

  void dispose() {
    invalidateStyle(keepRenderedPosition: false);
    _pendingUpdate = null;
  }
}

class _UserLocationUpdate {
  const _UserLocationUpdate({required this.data, required this.approximate});

  final GpsData data;
  final bool approximate;
}
