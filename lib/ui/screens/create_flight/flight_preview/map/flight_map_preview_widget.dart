import 'dart:io';
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

  const FlightMapPreviewWidget({
    super.key,
    required this.flightRoute,
    required this.flightInfo,
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

  // To avoid covering by bottom sheet
  Future<void> _moveCameraToTop() async {
    if (!mounted) return;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double shiftPx = screenHeight * 0.15;
    // On iOS, scrollBy(0, y) moves camera down (content up) given positive y.
    // On Android, negative y seems to produce the desired effect (user report).
    final double yShift = Platform.isIOS ? shiftPx : -shiftPx;

    await _mapController?.animateCamera(
      CameraUpdate.scrollBy(0.0, yShift),
      duration: Duration(milliseconds: 500),
    );
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    setState(() {
      _mapReady = true;
    });
  }

  void _onStyleLoaded() {
    // Style loaded, can now add custom layers
    if (_mapReady) {
      // Add a small delay to ensure style is fully loaded
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (mounted && _mapController != null) {
          await _moveCameraToTop();
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
  }

  Future<void> _syncPoiLayer() async {
    final controller = _mapController;
    if (!_routeLayersAdded || controller == null) return;

    final nextSignature = Object.hashAll(
      widget.flightInfo.poi.map((poi) => poi.name),
    );
    if (_poiSignature == nextSignature) return;
    _poiSignature = nextSignature;

    PoiLayer(poi: widget.flightInfo.poi).add(controller);
  }

  @override
  Widget build(BuildContext context) {
    double zoom = MapUtils.calculateZoomLevel(
      departure: route.departure,
      arrival: route.arrival,
    );
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: zoom.isFinite ? zoom : 1.0,
      ),
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
