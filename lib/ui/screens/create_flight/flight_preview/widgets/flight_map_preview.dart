import 'package:flymap/entity/flight_preview.dart';
import 'package:flymap/ui/map/layers/airports_layer.dart';
import 'package:flymap/ui/map/layers/corridor_layer.dart';
import 'package:flymap/ui/map/layers/dimming_layer.dart';
import 'package:flymap/ui/map/layers/waypoints_layer.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapPreview extends StatefulWidget {
  final FlightPreview flightPreview;

  const FlightMapPreview({super.key, required this.flightPreview});

  @override
  State<FlightMapPreview> createState() => _FlightMapPreviewState();
}

class _FlightMapPreviewState extends State<FlightMapPreview> {
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  late final FlightPreview preview = widget.flightPreview;

  late final LatLng _center = LatLng(
    MapUtils.center(
      departure: preview.departure,
      arrival: preview.arrival,
    ).latitude,
    MapUtils.center(
      departure: preview.departure,
      arrival: preview.arrival,
    ).longitude,
  );

  @override
  void initState() {
    super.initState();
    _fitMapToAirports();
  }

  void _fitMapToAirports() {
    double zoomLevel = MapUtils.calculateZoomLevel(
      departure: preview.departure,
      arrival: preview.arrival,
    );

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _center, zoom: zoomLevel),
      ),
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
          await _addFlightMapLayers(_mapController!);
        }
      });
    }
  }

  Future<void> _addFlightMapLayers(MapLibreMapController controller) async {
    [
      CorridorLayer(preview.corridor),
      WaypointsLayer(preview.waypoints),
      DimmingLayer(preview.corridor),
      AirportsLayer(
        departure: preview.departure,
        arrival: preview.arrival,
      ),
    ].forEach((layer) => layer.add(controller));
  }

  @override
  Widget build(BuildContext context) {
    double zoom = MapUtils.calculateZoomLevel(
      departure: preview.departure,
      arrival: preview.arrival,
    );
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(target: _center, zoom: zoom),
      styleString: "https://tiles.openfreemap.org/styles/liberty",
      onStyleLoadedCallback: _onStyleLoaded,
    );
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController!.dispose();
      _mapController = null;
    }
    super.dispose();
  }
}
