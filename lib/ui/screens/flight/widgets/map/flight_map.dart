import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/airports_layer.dart';
import 'package:flymap/ui/map/layers/corridor_layer.dart';
import 'package:flymap/ui/map/layers/dimming_layer.dart';
import 'package:flymap/ui/map/layers/user_layer.dart';
import 'package:flymap/ui/map/layers/waypoints_layer.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../viewmodel/flight_screen_cubit.dart';
import '../../viewmodel/flight_screen_state.dart';

class FlightMap extends StatefulWidget {
  final Flight flight;

  const FlightMap({super.key, required this.flight});

  @override
  State<FlightMap> createState() => _FlightMapState();
}

class _FlightMapState extends State<FlightMap> {
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  late final _waypoints = widget.flight.waypoints;
  late final _corridor = widget.flight.corridor;
  String? _styleString;
  final _logger = const Logger('FlightMapLoaded');
  bool _is3D = false;
  Circle? _userCircle;
  bool _followUser = false;
  final _styleMapper = FlightMapStyleMapper();

  late final LatLng _center = LatLng(
    MapUtils.center(
      departure: widget.flight.departure,
      arrival: widget.flight.arrival,
    ).latitude,
    MapUtils.center(
      departure: widget.flight.departure,
      arrival: widget.flight.arrival,
    ).longitude,
  );

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  /// Load style from assets and replace URL with local mbtiles path
  Future<void> _loadStyle() async {
    final path = widget.flight.flightMap?.filePath ?? '';
    _logger.log('Loading mbtiles style with path: $path');

    if (path.isEmpty) {
      _logger.log('No MBTiles file path found');
      return;
    }

    // Check if file exists
    final file = File(path);
    if (!await file.exists()) {
      _logger.log('MBTiles file does not exist: $path');
      return;
    }

    _logger.log('MBTiles file exists, loading style from assets');

    try {
      // Load the style from assets
      final styleString = await rootBundle.loadString(
        'assets/styles/openfreemap_offline_style.json',
      );

      final updated = _styleMapper.mapStyleWithMbtiles(
        styleString,
        file.absolute.path,
      );

      setState(() {
        _styleString = updated;
      });
    } catch (e) {
      _logger.error('Error loading style from assets: $e');
    }
  }

  void _goToUserLocationAndFollow() {
    final userLoc = _userCircle?.options.geometry;
    setState(() {
      _followUser = true;
    });
    if (userLoc != null) {
      final update = CameraUpdate.newLatLng(userLoc);
      _mapController?.animateCamera(update);
    }
  }

  // To avoid covering by bottom sheet
  Future<void> _moveCameraToTop() async {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double shiftPx = screenHeight * 0.2;
    await _mapController?.animateCamera(
      CameraUpdate.scrollBy(0.0, -shiftPx),
      duration: Duration(milliseconds: 0),
    );
  }

  void _onMapCreated(MapLibreMapController controller) {
    _logger.log('Map created successfully');
    _mapController = controller;

    _mapController!.onSymbolTapped.add(_onSymbolTapped);

    setState(() {
      _mapReady = true;
    });
  }

  void _onSymbolTapped(Symbol symbol) {
    // Example: stop follow and log tapped airport
    if (_followUser) setState(() => _followUser = false);

    _logger.log(
      'Symbol tapped: id=${symbol.id} text=${symbol.options.textField}',
    );
  }

  void _onStyleLoaded() async {
    _logger.log('Style loaded successfully');
    // Style loaded, can now add custom layers
    if (_mapReady) {
      await _moveCameraToTop();
      _addFlightMapLayers();
    }
  }

  void _addFlightMapLayers() {
    [
      CorridorLayer(_corridor),
      WaypointsLayer(_waypoints),
      DimmingLayer(_corridor),
      AirportsLayer(
        departure: widget.flight.departure,
        arrival: widget.flight.arrival,
      ),
    ].forEach((layer) => layer.add(_mapController!));
  }

  Future<void> _updateUserLocation(GpsData data) async {
    if (!_mapReady || _mapController == null) return;
    final lat = data.latitude;
    final lon = data.longitude;
    _logger.log('updateUserLocation lat: $lat, lon: $lon');
    if (lat == null || lon == null) return;
    final pos = LatLng(lat, lon);
    if (_userCircle == null) {
      _userCircle = await _mapController!.addCircle(UserLayer(pos).userOptions);
    } else {
      await _mapController!.updateCircle(
        _userCircle!,
        CircleOptions(geometry: pos),
      );
    }
    if (_followUser) {
      await _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_styleString == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading map style...'),
          ],
        ),
      );
    }

    double zoom = MapUtils.calculateZoomLevel(
      departure: widget.flight.departure,
      arrival: widget.flight.arrival,
    );
    final double controlsTopOffset =
        MediaQuery.of(context).padding.top + 2 * kToolbarHeight + 8;

    return BlocListener<FlightScreenCubit, FlightScreenState>(
      listener: (context, state) {
        if (state is FlightScreenLoaded && state.gpsData != null) {
          _updateUserLocation(state.gpsData!);
        }
      },
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (_followUser) {
                setState(() => _followUser = false);
              }
            },
            child: MapLibreMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: zoom,
              ),
              styleString: _styleString!,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),

          // Zoom/3D controls
          Positioned(
            top: controlsTopOffset,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  mini: true,
                  onPressed: () async {
                    if (_is3D) {
                      await _mapController?.animateCamera(
                        CameraUpdate.tiltTo(0),
                      );
                    } else {
                      // Switch to 3D with a modest tilt
                      await _mapController?.animateCamera(
                        CameraUpdate.tiltTo(45),
                      );
                    }
                    if (mounted) setState(() => _is3D = !_is3D);
                  },
                  child: Icon(
                    _is3D
                        ? Icons.threed_rotation
                        : Icons.threed_rotation_outlined,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  mini: true,
                  onPressed: _goToUserLocationAndFollow,
                  child: Icon(
                    _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.onSymbolTapped.remove(_onSymbolTapped);
    // Properly dispose of the map controller to close connections
    if (_mapController != null) {
      _mapController!.dispose();
      _mapController = null;
    }
    super.dispose();
  }
}
