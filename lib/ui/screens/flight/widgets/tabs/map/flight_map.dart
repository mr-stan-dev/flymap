import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/data/tiles_downloader/mbtiles_validator.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/ui/map/layers/flight_route_map_layers.dart';
import 'package:flymap/ui/map/layers/user_layer.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_controls.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_gps_status_badge.dart';
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
  GpsData? _pendingGpsData;
  bool _isApplyingUserLocation = false;
  int? _lastLoggedZoomTenths;
  String? _mapLoadError;

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
      _setMapLoadError(t.flight.map.offlineNotAvailable);
      return;
    }

    // Construct full path from filename (DB stores only the filename to avoid
    // iOS container UUID staleness)
    final fileName = p.basename(storedPath);
    final appDir = await getApplicationCacheDirectory();
    final resolvedPath = p.join(
      appDir.path,
      MapDownloadConfig.mbtilesDirectoryName,
      fileName,
    );
    final file = File(resolvedPath);

    if (!await file.exists()) {
      _logger.error('MBTiles file not found: $resolvedPath');
      _setMapLoadError(t.flight.map.offlineMissing);
      return;
    }
    _logger.log('Loading mbtiles: $fileName');
    _logger.log('Resolved MBTiles path: ${file.absolute.path}');

    final validationResult = await MbtilesValidator.validate(
      file.absolute.path,
      logger: _logger,
    );
    if (!validationResult.isValid) {
      _logger.error(
        'MBTiles validation failed for ${file.absolute.path}: '
        '${validationResult.errorMessage}',
      );
      _setMapLoadError(
        validationResult.errorMessage ?? t.flight.map.validationFailed,
      );
      return;
    }

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
        _mapLoadError = null;
      });
    } catch (e) {
      _logger.error('Error loading style from assets: $e');
      _setMapLoadError(t.flight.map.loadStyleFailed);
    }
  }

  void _setMapLoadError(String message) {
    if (!mounted) return;
    setState(() {
      _styleString = null;
      _mapLoadError = message;
    });
    _showMapErrorToast(message);
  }

  void _showMapErrorToast(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    });
  }

  Future<void> _toggleUserFollow() async {
    _showControlsTemporarily();

    if (_followUser) {
      setState(() {
        _followUser = false;
      });
      return;
    }

    final userLoc =
        _userCircle?.options.geometry ?? _userHeadingSymbol?.options.geometry;
    if (userLoc == null) return;

    setState(() {
      _followUser = true;
    });
    final update = CameraUpdate.newLatLng(userLoc);
    await _mapController?.animateCamera(update);
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
    _isMapInitialized = false;
    _pendingGpsData = null;

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
      await _addFlightMapLayers();

      if (mounted) {
        setState(() {
          _isMapInitialized = true;
        });
      }

      await _flushPendingGpsData();
    });
  }

  Future<void> _addFlightMapLayers() async {
    final controller = _mapController;
    if (controller == null) return;
    await FlightRouteMapLayers.add(
      controller: controller,
      route: widget.flight.route,
    );
  }

  Future<void> _updateUserLocation(GpsData data) async {
    _pendingGpsData = data;

    if (!_mapReady || _mapController == null || !_isMapInitialized) {
      return;
    }
    if (_isApplyingUserLocation) {
      return;
    }

    _isApplyingUserLocation = true;
    try {
      while (_pendingGpsData != null) {
        final next = _pendingGpsData!;
        _pendingGpsData = null;
        await _applyUserLocation(next);
      }
    } finally {
      _isApplyingUserLocation = false;
    }
  }

  Future<void> _applyUserLocation(GpsData data) async {
    if (!_mapReady || _mapController == null || !_isMapInitialized) return;
    final lat = data.latitude;
    final lon = data.longitude;
    _logger.log('updateUserLocation lat: $lat, lon: $lon');
    if (lat == null || lon == null) return;
    final pos = LatLng(lat, lon);
    final heading = data.course ?? 0;

    try {
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
    } catch (e) {
      _logger.error('Failed to apply user location marker: $e');
      _pendingGpsData = data;
      if (_isMapInitialized && mounted) {
        Future.delayed(const Duration(milliseconds: 250), () {
          final pending = _pendingGpsData;
          if (pending != null) {
            _updateUserLocation(pending);
          }
        });
      }
      return;
    }

    if (_followUser) {
      await _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }

  Future<void> _flushPendingGpsData() async {
    final pending = _pendingGpsData;
    if (pending == null) return;
    await _updateUserLocation(pending);
  }

  double _initialZoom() {
    final zoom = MapUtils.calculateZoomLevel(
      departure: widget.flight.departure,
      arrival: widget.flight.arrival,
    );
    return zoom.isFinite ? zoom : 1.0;
  }

  void _onCameraMove(CameraPosition cameraPosition) {
    final nextZoom = cameraPosition.zoom;
    if (!nextZoom.isFinite) {
      return;
    }

    final nextZoomTenths = (nextZoom * 10).round();
    if (_lastLoggedZoomTenths == nextZoomTenths) {
      return;
    }

    _lastLoggedZoomTenths = nextZoomTenths;
    _logger.log('Camera zoom: ${nextZoom.toStringAsFixed(1)}');
  }

  @override
  Widget build(BuildContext context) {
    if (_styleString == null) {
      return MapStyleLoadingView(
        message: _mapLoadError ?? t.flight.map.loadingStyle,
        isError: _mapLoadError != null,
      );
    }

    final initialZoom = _initialZoom();
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
                zoom: initialZoom,
              ),
              styleString: _styleString!,
              trackCameraPosition: true,
              onCameraMove: _onCameraMove,
              compassViewPosition: CompassViewPosition.bottomRight,
              compassViewMargins: const Point(16, 16),
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
          FlightMapControls(
            topOffset: controlsTopOffset,
            visible: _showControls || _followUser,
            is3D: _is3D,
            followUser: _followUser,
            onToggle3D: _toggle3D,
            onToggleFollowUser: _toggleUserFollow,
          ),
          Positioned(
            left: 8,
            bottom: 16,
            child: BlocBuilder<FlightScreenCubit, FlightScreenState>(
              buildWhen: (previous, current) {
                if (previous is FlightScreenLoaded &&
                    current is FlightScreenLoaded) {
                  return previous.gpsStatus != current.gpsStatus ||
                      previous.gpsUpdateTick != current.gpsUpdateTick ||
                      previous.gpsData?.accuracy != current.gpsData?.accuracy;
                }
                return previous.runtimeType != current.runtimeType;
              },
              builder: (context, state) {
                if (state is! FlightScreenLoaded) {
                  return const SizedBox.shrink();
                }
                return MapGpsStatusBadge(
                  gpsStatus: state.gpsStatus,
                  gpsData: state.gpsData,
                );
              },
            ),
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
