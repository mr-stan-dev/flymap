import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/gps_data.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_poi_controller.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_controls.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_style_loader.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_session_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_user_location_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_gps_status_badge.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_initializing_overlay.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_style_loading_view.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMap extends StatefulWidget {
  final Flight flight;

  const FlightMap({super.key, required this.flight});

  @override
  State<FlightMap> createState() => _FlightMapState();
}

class _FlightMapState extends State<FlightMap> {
  String? _styleString;
  final _logger = const Logger('FlightMapLoaded');
  bool _is3D = false;
  bool _followUser = false;
  bool _showControls = true;
  Timer? _controlsHideTimer;
  int? _lastLoggedZoomTenths;
  String? _mapLoadError;
  bool _featureTapListenerAttached = false;
  late final FlightMapSessionController _mapSession;
  late final FlightMapPoiController _poiController = FlightMapPoiController(
    logger: _logger,
    flight: widget.flight,
    analytics: GetIt.I.get(),
    wikiPreviewUseCase: GetIt.I.get(),
    connectivityChecker: GetIt.I.get(),
  );
  late final FlightMapUserLocationController _userLocationController =
      FlightMapUserLocationController(logger: _logger);
  late final FlightMapStyleLoader _styleLoader = FlightMapStyleLoader(
    logger: _logger,
    styleMapper: FlightMapStyleMapper(),
    mapAssetCacheService: GetIt.I.get(),
    crashlytics: GetIt.I.get(),
  );

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
    _mapSession = FlightMapSessionController(
      logger: _logger,
      flight: widget.flight,
    );
    _loadStyle();
    _scheduleControlsAutoHide();
  }

  /// Load style from assets and replace URL with local mbtiles path
  Future<void> _loadStyle() async {
    final result = await _styleLoader.load(widget.flight);
    if (!mounted) return;
    if (!result.isSuccess) {
      _setMapLoadError(result.errorMessage!);
      return;
    }

    setState(() {
      _styleString = result.styleString;
      _mapLoadError = null;
    });
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

    final userLoc = _userLocationController.currentUserLocation;
    if (userLoc == null) return;

    setState(() {
      _followUser = true;
    });
    final update = CameraUpdate.newLatLng(userLoc);
    await _mapSession.controller?.animateCamera(update);
  }

  Future<void> _toggle3D() async {
    _showControlsTemporarily();
    if (_is3D) {
      await _mapSession.controller?.animateCamera(CameraUpdate.tiltTo(0));
    } else {
      await _mapSession.controller?.animateCamera(CameraUpdate.tiltTo(45));
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
    _mapSession.onMapCreated(
      controller,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );

    controller.onSymbolTapped.add(_onSymbolTapped);
    if (!_featureTapListenerAttached) {
      controller.onFeatureTapped.add(_onFeatureTapped);
      _featureTapListenerAttached = true;
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    if (_followUser) setState(() => _followUser = false);

    _logger.log(
      'Symbol tapped: id=${symbol.id} text=${symbol.options.textField}',
    );
  }

  void _onStyleLoaded() {
    _mapSession.onStyleLoaded(
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      flushPendingGpsData: _flushPendingGpsData,
    );
  }

  void _onFeatureTapped(
    Point<double> point,
    LatLng _,
    String id,
    String layerId,
    Annotation? __,
  ) {
    if (!_poiController.isPoiLayer(layerId)) {
      return;
    }
    unawaited(
      _poiController.handlePoiTapAtPoint(
        point,
        context: context,
        controller: _mapSession.controller,
        routeLayersAdded: _mapSession.routeLayersAdded,
      ),
    );
  }

  Future<void> _updateUserLocation(GpsData data) async {
    await _userLocationController.updateUserLocation(
      data,
      controller: _mapSession.controller,
      isReady: _mapSession.isReadyForUserLocation,
      followUser: _followUser,
    );
  }

  Future<void> _flushPendingGpsData() async {
    await _userLocationController.flushPendingGpsData(
      controller: _mapSession.controller,
      isReady: _mapSession.isReadyForUserLocation,
      followUser: _followUser,
    );
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
          if (!_mapSession.isMapInitialized) const MapInitializingOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    _mapSession.controller?.onSymbolTapped.remove(_onSymbolTapped);
    if (_featureTapListenerAttached) {
      _mapSession.controller?.onFeatureTapped.remove(_onFeatureTapped);
      _featureTapListenerAttached = false;
    }
    _userLocationController.dispose();
    _mapSession.dispose();
    super.dispose();
  }
}
