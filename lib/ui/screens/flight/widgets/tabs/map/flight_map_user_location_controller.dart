import 'dart:async';

import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/user_layer.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapUserLocationController {
  FlightMapUserLocationController({required Logger logger}) : _logger = logger;

  final Logger _logger;

  Circle? _userCircle;
  Symbol? _userHeadingSymbol;
  GpsData? _pendingGpsData;
  bool _isApplyingUserLocation = false;

  LatLng? get currentUserLocation =>
      _userCircle?.options.geometry ?? _userHeadingSymbol?.options.geometry;

  Future<void> updateUserLocation(
    GpsData data, {
    required MapLibreMapController? controller,
    required bool isReady,
    required bool followUser,
  }) async {
    _pendingGpsData = data;

    if (controller == null || !isReady) return;
    if (_isApplyingUserLocation) return;

    _isApplyingUserLocation = true;
    try {
      while (_pendingGpsData != null) {
        final next = _pendingGpsData!;
        _pendingGpsData = null;
        await _applyUserLocation(
          next,
          controller: controller,
          isReady: isReady,
          followUser: followUser,
        );
      }
    } finally {
      _isApplyingUserLocation = false;
    }
  }

  Future<void> _applyUserLocation(
    GpsData data, {
    required MapLibreMapController controller,
    required bool isReady,
    required bool followUser,
  }) async {
    if (!isReady) return;
    final lat = data.latitude;
    final lon = data.longitude;
    _logger.log('updateUserLocation lat: $lat, lon: $lon');
    if (lat == null || lon == null) return;
    final pos = LatLng(lat, lon);
    final heading = data.course ?? 0;

    try {
      if (_userCircle == null) {
        _userCircle = await controller.addCircle(UserLayer.markerCircle(pos));
      } else {
        await controller.updateCircle(
          _userCircle!,
          CircleOptions(geometry: pos),
        );
      }

      if (_userHeadingSymbol == null) {
        _userHeadingSymbol = await controller.addSymbol(
          UserLayer.headingArrow(pos, heading),
        );
      } else {
        await controller.updateSymbol(
          _userHeadingSymbol!,
          UserLayer.headingArrow(pos, heading),
        );
      }
    } catch (error) {
      _logger.error('Failed to apply user location marker: $error');
      _pendingGpsData = data;
      if (isReady) {
        Future.delayed(const Duration(milliseconds: 250), () {
          final pending = _pendingGpsData;
          if (pending != null) {
            unawaited(
              updateUserLocation(
                pending,
                controller: controller,
                isReady: isReady,
                followUser: followUser,
              ),
            );
          }
        });
      }
      return;
    }

    if (followUser) {
      await controller.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }

  Future<void> flushPendingGpsData({
    required MapLibreMapController? controller,
    required bool isReady,
    required bool followUser,
  }) async {
    final pending = _pendingGpsData;
    if (pending == null) return;
    await updateUserLocation(
      pending,
      controller: controller,
      isReady: isReady,
      followUser: followUser,
    );
  }

  void dispose() {
    _userCircle = null;
    _userHeadingSymbol = null;
    _pendingGpsData = null;
    _isApplyingUserLocation = false;
  }
}
