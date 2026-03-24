import 'dart:async';
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
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_controls.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_initializing_overlay.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_style_loading_view.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  Symbol? _userHeadingSymbol;
  bool _followUser = false;
  bool _showControls = true;
  Timer? _controlsHideTimer;
  final _styleMapper = FlightMapStyleMapper();
  bool _isMapInitialized = false;

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
    _scheduleControlsAutoHide();
  }

  /// Load style from assets and replace URL with local mbtiles path
  Future<void> _loadStyle() async {
    final storedPath = widget.flight.flightMap?.filePath ?? '';
    if (storedPath.isEmpty) {
      _logger.log('No MBTiles file path found');
      return;
    }

    // Construct full path from filename (DB stores only the filename to avoid
    // iOS container UUID staleness)
    final fileName = p.basename(storedPath);
    final appDir = await getApplicationCacheDirectory();
    final resolvedPath = p.join(appDir.path, 'mbtiles', fileName);
    final file = File(resolvedPath);

    if (!await file.exists()) {
      _logger.error('MBTiles file not found: $resolvedPath');
      return;
    }
    _logger.log('Loading mbtiles: $fileName');

    try {
      // Load the style from assets
      final styleString = await rootBundle.loadString(
        'assets/styles/openfreemap_offline_style.json',
      );

      final cacheDir = (await getApplicationCacheDirectory()).path;
      final updated = _styleMapper.mapStyleWithMbtiles(
        styleString,
        file.absolute.path,
        cacheDir: cacheDir,
      );

      setState(() {
        _styleString = updated;
      });
    } catch (e) {
      _logger.error('Error loading style from assets: $e');
    }
  }

  void _goToUserLocationAndFollow() {
    _showControlsTemporarily();
    final userLoc =
        _userCircle?.options.geometry ?? _userHeadingSymbol?.options.geometry;
    setState(() {
      _followUser = true;
    });
    if (userLoc != null) {
      final update = CameraUpdate.newLatLng(userLoc);
      _mapController?.animateCamera(update);
    }
  }

  Future<void> _toggle3D() async {
    _showControlsTemporarily();
    if (_is3D) {
      await _mapController?.animateCamera(CameraUpdate.tiltTo(0));
    } else {
      await _mapController?.animateCamera(CameraUpdate.tiltTo(45));
    }
    if (mounted) {
      setState(() => _is3D = !_is3D);
    }
  }

  void _showControlsTemporarily() {
    if (!mounted) return;
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
    }
    _scheduleControlsAutoHide();
  }

  void _scheduleControlsAutoHide() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || _followUser) return;
      setState(() {
        _showControls = false;
      });
    });
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
    if (_followUser) setState(() => _followUser = false);

    _logger.log(
      'Symbol tapped: id=${symbol.id} text=${symbol.options.textField}',
    );
  }

  void _onStyleLoaded() {
    _logger.log('Style loaded successfully');
    if (!_mapReady || !mounted) return;

    // Delay camera operations until the native map view has a valid frame.
    // simple delay is sufficient to avoid std::domain_error
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted || _mapController == null) return;
      _addFlightMapLayers();

      if (mounted) {
        setState(() {
          _isMapInitialized = true;
        });
      }
    });
  }

  void _addFlightMapLayers() {
    final layers = [
      CorridorLayer(_corridor),
      WaypointsLayer(_waypoints),
      DimmingLayer(_corridor),
      AirportsLayer(
        departure: widget.flight.departure,
        arrival: widget.flight.arrival,
      ),
    ];

    for (final layer in layers) {
      layer.add(_mapController!);
    }
  }

  Future<void> _updateUserLocation(GpsData data) async {
    if (!_mapReady || _mapController == null) return;
    final lat = data.latitude;
    final lon = data.longitude;
    _logger.log('updateUserLocation lat: $lat, lon: $lon');
    if (lat == null || lon == null) return;
    final pos = LatLng(lat, lon);
    final heading = data.course ?? 0;

    if (_userCircle == null) {
      _userCircle = await _mapController!.addCircle(
        UserLayer.markerCircle(pos),
      );
    } else {
      await _mapController!.updateCircle(
        _userCircle!,
        CircleOptions(geometry: pos),
      );
    }

    if (_userHeadingSymbol == null) {
      _userHeadingSymbol = await _mapController!.addSymbol(
        UserLayer.headingArrow(pos, heading),
      );
    } else {
      await _mapController!.updateSymbol(
        _userHeadingSymbol!,
        UserLayer.headingArrow(pos, heading),
      );
    }

    if (_followUser) {
      await _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_styleString == null) {
      return const MapStyleLoadingView();
    }

    final double zoom = MapUtils.calculateZoomLevel(
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
              _showControlsTemporarily();
              if (_followUser) {
                setState(() => _followUser = false);
              }
            },
            child: MapLibreMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: zoom.isFinite ? zoom : 1.0,
              ),
              styleString: _styleString!,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
          FlightMapControls(
            topOffset: controlsTopOffset,
            visible: _showControls || _followUser,
            is3D: _is3D,
            followUser: _followUser,
            onToggle3D: _toggle3D,
            onToggleFollowUser: _goToUserLocationAndFollow,
          ),
          if (!_isMapInitialized) const MapInitializingOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    _mapController?.onSymbolTapped.remove(_onSymbolTapped);
    _userCircle = null;
    _userHeadingSymbol = null;
    _mapController = null;
    _mapReady = false;
    super.dispose();
  }
}
