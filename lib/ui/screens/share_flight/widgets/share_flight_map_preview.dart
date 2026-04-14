import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/map/layers/flight_route_map_layers.dart';
import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/map_style_safety.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_initializing_overlay.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class ShareFlightMapPreview extends StatefulWidget {
  const ShareFlightMapPreview({
    required this.route,
    required this.styleString,
    super.key,
  });

  final FlightRoute route;
  final String styleString;

  @override
  State<ShareFlightMapPreview> createState() => _ShareFlightMapPreviewState();
}

class _ShareFlightMapPreviewState extends State<ShareFlightMapPreview> {
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  bool _isMapInitialized = false;
  bool _layersAdded = false;
  int _styleGeneration = 0;

  late final LatLng _center = MapUtils.routeCenter(widget.route).toMapLatLon();

  @override
  void didUpdateWidget(covariant ShareFlightMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.styleString != widget.styleString) {
      _invalidateStyleState();
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _invalidateStyleState();
    _mapController = controller;
    setState(() {
      _mapReady = true;
    });
  }

  void _onStyleLoaded() {
    if (!_mapReady || !mounted || _layersAdded) return;
    final styleGeneration = ++_styleGeneration;
    _layersAdded = true;
    _isMapInitialized = false;

    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!_isCurrentStyleGeneration(styleGeneration)) return;
      final controller = _mapController;
      if (controller == null) return;

      try {
        await _addLayers(controller);
      } on PlatformException catch (error) {
        if (isStaleStylePlatformException(error)) {
          return;
        }
        return;
      }

      if (_isCurrentStyleGeneration(styleGeneration)) {
        setState(() {
          _isMapInitialized = true;
        });
      }
    });
  }

  Future<void> _addLayers(MapLibreMapController controller) async {
    await FlightRouteMapLayers.add(
      controller: controller,
      route: widget.route,
      dashedPathSourceId: 'share-route-source',
      dashedPathLayerId: 'share-route-layer',
    );
  }

  bool _isCurrentStyleGeneration(int generation) {
    return mounted && generation == _styleGeneration;
  }

  void _invalidateStyleState() {
    _styleGeneration++;
    _layersAdded = false;
    _isMapInitialized = false;
  }

  @override
  Widget build(BuildContext context) {
    final zoom = MapUtils.calculateZoomLevel(
      departure: widget.route.departure,
      arrival: widget.route.arrival,
    );
    return Stack(
      children: [
        MapLibreMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: zoom.isFinite ? zoom : 1.0,
          ),
          styleString: widget.styleString,
          compassViewPosition: CompassViewPosition.bottomRight,
          compassViewMargins: const Point(16, 16),
          onStyleLoadedCallback: _onStyleLoaded,
        ),
        if (!_isMapInitialized) const MapInitializingOverlay(),
      ],
    );
  }

  @override
  void dispose() {
    _mapController = null;
    _mapReady = false;
    _styleGeneration++;
    super.dispose();
  }
}
