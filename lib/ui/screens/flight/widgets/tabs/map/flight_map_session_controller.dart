import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/flight_route_map_layers.dart';
import 'package:flymap/ui/map/layers/poi_layer.dart';
import 'package:flymap/ui/map/map_style_safety.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapSessionController {
  FlightMapSessionController({required Logger logger, required Flight flight})
    : _logger = logger,
      _flight = flight;

  static const Duration _layerInitRetryDelay = Duration(milliseconds: 120);
  static const int _maxLayerInitAttempts = 6;

  final Logger _logger;
  final Flight _flight;

  MapLibreMapController? _controller;
  bool _mapReady = false;
  bool _isMapInitialized = false;
  bool _routeLayersAdded = false;
  int _styleGeneration = 0;
  int _poiSignature = 0;

  MapLibreMapController? get controller => _controller;
  bool get isMapInitialized => _isMapInitialized;
  bool get routeLayersAdded => _routeLayersAdded;

  bool get isReadyForUserLocation =>
      _mapReady && _controller != null && _isMapInitialized;

  void onMapCreated(
    MapLibreMapController controller, {
    VoidCallback? onStateChanged,
  }) {
    _logger.log('Map created successfully');
    _invalidateStyleState();
    _controller = controller;
    _mapReady = true;
    _isMapInitialized = false;
    onStateChanged?.call();
  }

  void onStyleLoaded({
    required VoidCallback onStateChanged,
    required Future<void> Function() flushPendingGpsData,
  }) {
    _logger.log('Style loaded successfully');
    if (!_mapReady) return;
    final styleGeneration = ++_styleGeneration;
    _routeLayersAdded = false;
    _poiSignature = 0;
    _isMapInitialized = false;
    onStateChanged();
    unawaited(
      _initializeStyleLayers(
        styleGeneration,
        onStateChanged: onStateChanged,
        flushPendingGpsData: flushPendingGpsData,
        attempt: 1,
      ),
    );
  }

  Future<void> _initializeStyleLayers(
    int styleGeneration, {
    required VoidCallback onStateChanged,
    required Future<void> Function() flushPendingGpsData,
    required int attempt,
  }) async {
    if (!_isCurrentStyleGeneration(styleGeneration)) return;

    try {
      await _addFlightMapLayers(expectedStyleGeneration: styleGeneration);
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale flight map style update: $error');
        return;
      }

      if (attempt < _maxLayerInitAttempts) {
        _logger.log(
          'Retrying flight map layer init '
          '(attempt $attempt/$_maxLayerInitAttempts): $error',
        );
        await Future<void>.delayed(_layerInitRetryDelay);
        if (_isCurrentStyleGeneration(styleGeneration)) {
          unawaited(
            _initializeStyleLayers(
              styleGeneration,
              onStateChanged: onStateChanged,
              flushPendingGpsData: flushPendingGpsData,
              attempt: attempt + 1,
            ),
          );
        }
        return;
      }

      _logger.error('Failed to update flight map style layers: $error');
      return;
    }

    if (_isCurrentStyleGeneration(styleGeneration)) {
      _isMapInitialized = true;
      onStateChanged();
    }

    if (_isCurrentStyleGeneration(styleGeneration)) {
      await flushPendingGpsData();
    }
  }

  Future<void> _addFlightMapLayers({
    required int expectedStyleGeneration,
  }) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _controller;
    if (controller == null) return;
    await FlightRouteMapLayers.add(
      controller: controller,
      route: _flight.route,
    );
    _routeLayersAdded = true;
    await _syncPoiLayer(expectedStyleGeneration: expectedStyleGeneration);
  }

  Future<void> _syncPoiLayer({required int expectedStyleGeneration}) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _controller;
    if (!_routeLayersAdded || controller == null) return;
    final pois = _flight.info.poi;
    final nextSignature = Object.hashAll(pois.map((p) => p.qid));
    if (_poiSignature == nextSignature) return;
    _poiSignature = nextSignature;
    _logger.log('Syncing POI layer count=${pois.length}');
    try {
      await PoiLayer(poi: pois).add(controller);
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale flight map POI sync: $error');
        return;
      }
      _logger.error('Failed to sync flight map POI layer: $error');
    }
  }

  bool _isCurrentStyleGeneration(int generation) {
    return generation == _styleGeneration;
  }

  void _invalidateStyleState() {
    _styleGeneration++;
    _routeLayersAdded = false;
    _poiSignature = 0;
  }

  void dispose() {
    _controller = null;
    _mapReady = false;
    _routeLayersAdded = false;
    _isMapInitialized = false;
    _styleGeneration++;
    _poiSignature = 0;
  }
}
