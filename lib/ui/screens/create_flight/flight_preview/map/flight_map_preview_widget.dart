import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/map/layers/flight_route_map_layers.dart';
import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/poi_layer.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapPreviewWidget extends StatefulWidget {
  final FlightRoute flightRoute;
  final FlightInfo flightInfo;
  final double minZoom;
  final double maxZoom;

  const FlightMapPreviewWidget({
    super.key,
    required this.flightRoute,
    required this.flightInfo,
    required this.minZoom,
    required this.maxZoom,
  });

  @override
  State<FlightMapPreviewWidget> createState() => _FlightMapPreviewWidgetState();
}

class _FlightMapPreviewWidgetState extends State<FlightMapPreviewWidget> {
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  late final FlightRoute route = widget.flightRoute;
  bool _routeLayersAdded = false;
  int _poiSignature = 0;

  late final LatLng _center = MapUtils.routeCenter(
    widget.flightRoute,
  ).toMapLatLon();

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    setState(() {
      _mapReady = true;
    });
    unawaited(_clampCameraZoomToBounds());
  }

  void _onStyleLoaded() {
    // Style loaded, can now add custom layers
    if (_mapReady) {
      // Add a small delay to ensure style is fully loaded
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (mounted && _mapController != null) {
          await _addFlightMapLayers(_mapController!);
          await _syncPoiLayer();
        }
      });
    }
  }

  Future<void> _addFlightMapLayers(MapLibreMapController controller) async {
    await FlightRouteMapLayers.add(controller: controller, route: route);
    _routeLayersAdded = true;
  }

  @override
  void didUpdateWidget(covariant FlightMapPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flightInfo != widget.flightInfo) {
      _syncPoiLayer();
    }
    final zoomBoundsChanged =
        oldWidget.minZoom != widget.minZoom ||
        oldWidget.maxZoom != widget.maxZoom;
    if (zoomBoundsChanged) {
      unawaited(_clampCameraZoomToBounds());
    }
  }

  Future<void> _clampCameraZoomToBounds() async {
    final controller = _mapController;
    if (controller == null) return;

    final currentZoom = controller.cameraPosition?.zoom;
    if (currentZoom == null || !currentZoom.isFinite) return;

    final minZoom = widget.minZoom;
    final maxZoom = widget.maxZoom;
    final clampedZoom = currentZoom.clamp(minZoom, maxZoom).toDouble();
    if ((clampedZoom - currentZoom).abs() < 0.001) return;

    await controller.animateCamera(CameraUpdate.zoomTo(clampedZoom));
  }

  Future<void> _syncPoiLayer() async {
    final controller = _mapController;
    if (!_routeLayersAdded || controller == null) return;

    final nextSignature = Object.hashAll(
      widget.flightInfo.poi.map((poi) => poi.name),
    );
    if (_poiSignature == nextSignature) return;
    _poiSignature = nextSignature;

    await PoiLayer(poi: widget.flightInfo.poi).add(controller);
  }

  @override
  Widget build(BuildContext context) {
    double zoom = MapUtils.calculateZoomLevel(
      departure: route.departure,
      arrival: route.arrival,
    );
    final initialZoom = (zoom.isFinite ? zoom : 1.0)
        .clamp(widget.minZoom, widget.maxZoom)
        .toDouble();
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(target: _center, zoom: initialZoom),
      minMaxZoomPreference: MinMaxZoomPreference(
        widget.minZoom,
        widget.maxZoom,
      ),
      trackCameraPosition: true,
      styleString: "https://tiles.openfreemap.org/styles/liberty",
      compassViewPosition: CompassViewPosition.bottomRight,
      compassViewMargins: const Point(16, 16),
      onStyleLoadedCallback: _onStyleLoaded,
    );
  }

  @override
  void dispose() {
    _mapController = null;
    _mapReady = false;
    _routeLayersAdded = false;
    super.dispose();
  }
}
