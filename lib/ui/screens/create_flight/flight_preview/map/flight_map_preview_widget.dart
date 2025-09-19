import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/map/layers/airports_layer.dart';
import 'package:flymap/ui/map/layers/corridor_layer.dart';
import 'package:flymap/ui/map/layers/dimming_layer.dart';
import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/poi_layer.dart';
import 'package:flymap/ui/map/layers/waypoints_layer.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
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

  late final LatLng _center = MapUtils.routeCenter(widget.flightRoute).toMapLatLon();

  // To avoid covering by bottom sheet
  Future<void> _moveCameraToTop() async {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double shiftPx = screenHeight * 0.2;
    await _mapController?.animateCamera(
      CameraUpdate.scrollBy(0.0, -shiftPx),
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
        }
      });
    }
  }

  Future<void> _addFlightMapLayers(MapLibreMapController controller) async {
    [
      CorridorLayer(route.corridor),
      WaypointsLayer(route.waypoints),
      DimmingLayer(route.corridor),
      AirportsLayer(departure: route.departure, arrival: route.arrival),
    ].forEach((layer) => layer.add(controller));
  }

  @override
  Widget build(BuildContext context) {
    double zoom = MapUtils.calculateZoomLevel(
      departure: route.departure,
      arrival: route.arrival,
    );
    return BlocListener<FlightPreviewCubit, FlightPreviewState>(
      listener: (context, state) {
        if (state is FlightMapPreviewMapState && _mapController != null) {
          PoiLayer(poi: state.flightInfo.poi).add(_mapController!);
        }
      },
      listenWhen: (oldState, newState) {
        final newLoaded = newState as FlightMapPreviewMapState?;
        return newLoaded != null && !newLoaded.flightInfo.isEmpty;
      },
      child: MapLibreMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(target: _center, zoom: zoom),
        styleString: "https://tiles.openfreemap.org/styles/liberty",
        onStyleLoadedCallback: _onStyleLoaded,
      ),
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
