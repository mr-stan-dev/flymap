import 'package:flymap/data/great_circle_route_provider.dart';
import 'package:flymap/data/route_corridor_provider.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/map_utils.dart';
import 'package:flymap/ui/widgets/map/map_builder.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flymap/data/sprite_service.dart';

class FlightMapPreview extends StatefulWidget {
  final Airport departure;
  final Airport arrival;

  const FlightMapPreview({
    super.key,
    required this.departure,
    required this.arrival,
  });

  @override
  State<FlightMapPreview> createState() => _FlightMapPreviewState();
}

class _FlightMapPreviewState extends State<FlightMapPreview> {
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  List<latlong.LatLng> _routePoints = [];
  List<latlong.LatLng> _corridorPoints = [];

  late final LatLng _center = LatLng(
    MapUtils.center(
      departure: widget.departure,
      arrival: widget.arrival,
    ).latitude,
    MapUtils.center(
      departure: widget.departure,
      arrival: widget.arrival,
    ).longitude,
  );

  @override
  void initState() {
    super.initState();
    _generateRouteAndCorridor();
  }

  Future<void> _generateRouteAndCorridor() async {
    try {
      // Generate great circle route
      final routeProvider = GreatCircleRouteProvider();
      final route = routeProvider.calculateRoute(
        widget.departure.latLon,
        widget.arrival.latLon,
      );

      // Generate corridor
      final corridorProvider = RouteCorridorProvider();
      final corridor = corridorProvider.calculateCorridor(
        route,
        widthKm: 100.0,
      );

      setState(() {
        _routePoints = route;
        _corridorPoints = corridor;
      });

      // Fit to route after route is generated
      if (mounted && _mapReady) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _fitMapToAirports();
          }
        });
      }
    } catch (e) {
      // Handle error silently or show a snackbar
    }
  }

  void _fitMapToAirports() {
    double zoomLevel = MapUtils.calculateZoomLevel(
      departure: widget.departure,
      arrival: widget.arrival,
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
          await _addRouteAndCorridor(_mapController!);
        }
      });
    }
  }

  Future<void> _addRouteAndCorridor(MapLibreMapController controller) async {
    controller.showCorridor(_corridorPoints);
    controller.showRoute(_routePoints);
    controller.showDimmingLayer(_corridorPoints);
    controller.showAirports(widget.departure, widget.arrival);
  }

  @override
  Widget build(BuildContext context) {
    double zoom = MapUtils.calculateZoomLevel(
      departure: widget.departure,
      arrival: widget.arrival,
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
