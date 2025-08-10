import 'dart:convert';
import 'dart:io';

import 'package:flymap/entity/flight.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map_utils.dart';
import 'package:flymap/ui/widgets/map/map_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flymap/entity/gps_data.dart';
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
      final style = jsonDecode(styleString) as Map<String, dynamic>;

      // Replace the URL with our local mbtiles file path
      // Use absolute path with proper mbtiles:// protocol
      if (style['sources'] != null &&
          style['sources']['openmaptiles'] != null) {
        final absolutePath = file.absolute.path;
        style['sources']['openmaptiles']['url'] = 'mbtiles://$absolutePath';
        _logger.log('Updated mbtiles URL to: mbtiles://$absolutePath');
      }

      setState(() {
        _styleString = jsonEncode(style);
      });
    } catch (e) {
      _logger.error('Error loading style from assets: $e');
    }
  }

  void _animateToUserLocation() {
    final userLoc = _userCircle?.options.geometry;
    if (userLoc != null) {
      final pos = CameraPosition(target: userLoc, zoom: 5);
      final update = CameraUpdate.newCameraPosition(pos);
      _mapController?.animateCamera(update);
    }
  }

  void _fitMapToAirports() {
    double zoomLevel = MapUtils.calculateZoomLevel(
      departure: widget.flight.departure,
      arrival: widget.flight.arrival,
    );
    final pos = CameraPosition(target: _center, zoom: zoomLevel);
    final update = CameraUpdate.newCameraPosition(pos);
    _mapController?.animateCamera(update);
  }

  void _onMapCreated(MapLibreMapController controller) {
    _logger.log('Map created successfully');
    _mapController = controller;
    setState(() {
      _mapReady = true;
    });
  }

  void _onStyleLoaded() {
    _logger.log('Style loaded successfully');
    // Style loaded, can now add custom layers
    if (_mapReady) {
      // Add a small delay to ensure style is fully loaded
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _fitMapToAirports();
          _addRouteAndCorridor();
        }
      });
    }
  }

  void _addRouteAndCorridor() {
    _mapController?.showRoute(_waypoints);
    _mapController?.showCorridor(_corridor);
    _mapController?.showDimmingLayer(_corridor);
    _mapController?.showAirports(
      widget.flight.departure,
      widget.flight.arrival,
    );
  }

  Future<void> _updateUserLocation(GpsData data) async {
    if (!_mapReady || _mapController == null) return;
    final lat = data.latitude;
    final lon = data.longitude;
    if (lat == null || lon == null) return;
    final pos = LatLng(lat, lon);

    if (_userCircle == null) {
      _userCircle = await _mapController!.addCircle(
        CircleOptions(
          geometry: pos,
          circleColor: '#2E7DFF',
          circleRadius: 6.0,
          circleOpacity: 0.9,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.0,
        ),
      );
    } else {
      await _mapController!.updateCircle(
        _userCircle!,
        CircleOptions(geometry: pos),
      );
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
          MapLibreMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: zoom),
            styleString: _styleString!,
            onStyleLoadedCallback: _onStyleLoaded,
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
                        CameraUpdate.tiltTo(50.0),
                      );
                    }
                    if (mounted) setState(() => _is3D = !_is3D);
                  },
                  child: Text(_is3D ? '2D' : '3D'),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  backgroundColor: Colors.black.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  mini: true,
                  onPressed: _animateToUserLocation,
                  child: Icon(Icons.my_location),
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
    // Properly dispose of the map controller to close connections
    if (_mapController != null) {
      _mapController!.dispose();
      _mapController = null;
    }
    super.dispose();
  }
}
