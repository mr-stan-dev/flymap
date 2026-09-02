import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/mappers/flight_map_mapper.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_map_position.dart';
import 'package:flymap/domain/entity/offline_map_style.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/repository/map_preferences_repository.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_state.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/controllers/flight_map_camera_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/controllers/flight_map_day_night_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/controllers/flight_map_style_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/controllers/flight_map_style_transition_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/controllers/selected_region_overlay_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_poi_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_session_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_style_loader.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/flight_map_user_location_controller.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_controls.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_initializing_overlay.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/map_style_loading_view.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/widgets/flight_map_bottom_status_overlay.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/map/widgets/flight_map_gps_badge_overlay.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:get_it/get_it.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMap extends StatefulWidget {
  final Flight flight;
  final double topPadding;
  final VoidCallback? onGpsHelpTap;

  const FlightMap({
    super.key,
    required this.flight,
    required this.topPadding,
    this.onGpsHelpTap,
  });

  @override
  State<FlightMap> createState() => _FlightMapState();
}

class _FlightMapState extends State<FlightMap> {
  static const String _routePathLayerId = 'flight-route-path-layer';

  String? _styleString;
  final _logger = const Logger('FlightMapLoaded');
  String? _mapLoadError;
  bool _featureTapListenerAttached = false;
  int _styleLoadRequestId = 0;
  late final FlightMapSessionController _mapSession;
  late final FlightMapCameraController _cameraController =
      FlightMapCameraController(logger: _logger);
  late final SelectedRegionOverlayController _selectedRegionOverlayController =
      SelectedRegionOverlayController(
        logger: _logger,
        route: widget.flight.route,
        routePathLayerId: _routePathLayerId,
        routeRegions: widget.flight.info.routeRegions,
      );
  late final FlightMapDayNightController _dayNightController =
      FlightMapDayNightController(route: widget.flight.route, logger: _logger);
  late final MapPreferencesRepository _mapPreferencesRepository =
      MapPreferencesRepository();
  late final FlightMapStyleController _styleController =
      FlightMapStyleController(
        mapPreferencesRepository: _mapPreferencesRepository,
      );
  late final FlightMapStyleTransitionController _styleTransitionController =
      FlightMapStyleTransitionController();
  late final FlightMapPoiController _poiController = FlightMapPoiController(
    logger: _logger,
    flight: widget.flight,
    analytics: GetIt.I.get(),
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

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    final initialZoom = _initialZoom();
    _mapSession = FlightMapSessionController(
      logger: _logger,
      flight: widget.flight,
    );
    _cameraController.addListener(_onControllerChanged);
    _dayNightController.addListener(_onControllerChanged);
    _styleController.addListener(_onControllerChanged);
    _styleTransitionController.addListener(_onControllerChanged);
    unawaited(_loadInitialStyle());
    _cameraController.start(initialZoom: initialZoom);
    unawaited(_dayNightController.init());
  }

  Future<void> _loadInitialStyle() async {
    await _styleController.init();
    await _loadStyle(style: _styleController.style);
  }

  /// Load style from assets and replace URL with local mbtiles path.
  Future<bool> _loadStyle({required OfflineMapStyle style}) async {
    final requestId = ++_styleLoadRequestId;
    _styleTransitionController.beginPreparing();
    if (mounted) {
      setState(() {
        if (_styleString == null) {
          _mapLoadError = null;
        }
      });
    }

    final result = await _styleLoader.load(widget.flight, style: style);
    if (!mounted) return false;
    if (requestId != _styleLoadRequestId) {
      _styleTransitionController.fail();
      return false;
    }

    if (!result.isSuccess) {
      _styleTransitionController.fail();
      if (_styleString == null) {
        _setMapLoadError(result.errorMessage!);
      } else {
        _showMapErrorToast(result.errorMessage!);
      }
      return false;
    }

    _beginStyleSwap();
    _styleTransitionController.beginApplying();
    setState(() {
      _styleString = result.styleString;
      _mapLoadError = null;
    });
    return true;
  }

  void _setMapLoadError(String message) {
    if (!mounted) return;
    _styleTransitionController.fail();
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
    await _flushPendingGpsData();
    await _cameraController.toggleUserFollow(
      controller: _mapSession.controller,
      userLocation: _userLocationController.currentUserLocation,
      userHeading: _userLocationController.currentUserHeading,
    );
  }

  Future<void> _toggle3D() async {
    await _cameraController.toggle3D(_mapSession.controller);
  }

  Future<void> _toggleMapStyle() async {
    if (_styleTransitionController.isLoading) {
      return;
    }

    final nextStyle = _styleController.nextStyle;
    final loaded = await _loadStyle(style: nextStyle);
    if (!loaded) {
      return;
    }
    await _styleController.setStyle(nextStyle);
  }

  void _onMapCreated(MapLibreMapController controller) {
    final previousController = _mapSession.controller;
    if (previousController != null &&
        !identical(previousController, controller)) {
      previousController.onSymbolTapped.remove(_onSymbolTapped);
      if (_featureTapListenerAttached) {
        previousController.onFeatureTapped.remove(_onFeatureTapped);
        _featureTapListenerAttached = false;
      }
    }

    _invalidateStyleBoundControllers();
    _dayNightController.updateMapContext(
      controller: controller,
      routeLayersAdded: _mapSession.routeLayersAdded,
      belowLayerId: _routePathLayerId,
    );
    _mapSession.onMapCreated(
      controller,
      onStateChanged: _handleMapSessionStateChanged,
    );

    controller.onSymbolTapped.add(_onSymbolTapped);
    if (!_featureTapListenerAttached) {
      controller.onFeatureTapped.add(_onFeatureTapped);
      _featureTapListenerAttached = true;
    }
  }

  void _onSymbolTapped(Symbol symbol) {
    _cameraController.handleSymbolTap();

    _logger.log(
      'Symbol tapped: id=${symbol.id} text=${symbol.options.textField}',
    );
  }

  void _onStyleLoaded() {
    _invalidateStyleBoundControllers();
    _mapSession.onStyleLoaded(
      onStateChanged: _handleMapSessionStateChanged,
      flushPendingGpsData: _flushPendingGpsData,
    );
  }

  void _beginStyleSwap() {
    _mapSession.beginStyleReload(onStateChanged: _handleMapSessionStateChanged);
    _invalidateStyleBoundControllers();
  }

  void _invalidateStyleBoundControllers() {
    _userLocationController.invalidateStyle();
    _dayNightController.invalidateStyle();
  }

  void _handleMapSessionStateChanged() {
    if (!mounted) {
      return;
    }

    if (_mapSession.routeLayersAdded) {
      _selectedRegionOverlayController.updateRouteRegions(
        widget.flight.info.routeRegions,
      );
      unawaited(
        _selectedRegionOverlayController.sync(
          _mapSession.controller,
          routeLayersAdded: _mapSession.routeLayersAdded,
        ),
      );
      _dayNightController.updateMapContext(
        controller: _mapSession.controller,
        routeLayersAdded: _mapSession.routeLayersAdded,
        belowLayerId: _routePathLayerId,
      );
      unawaited(_dayNightController.handleMapReady());
    }

    if (_mapSession.isMapInitialized) {
      _styleTransitionController.complete();
    }

    setState(() {});
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

  void _onGeoRegionSelectionChanged(RouteRegion? region) {
    final changed = _selectedRegionOverlayController.selectRegion(region);
    if (!changed) {
      return;
    }
    if (region != null) {
      _cameraController.stopFollowing();
    }
    unawaited(
      _selectedRegionOverlayController.sync(
        _mapSession.controller,
        routeLayersAdded: _mapSession.routeLayersAdded,
      ),
    );
  }

  Future<void> _updateUserLocation(FlightMapPosition position) async {
    await _userLocationController.updateUserLocation(
      position.data,
      approximate: position.isApproximate,
      controller: _mapSession.controller,
      isReady: () => _mapSession.isReadyForUserLocation,
      shouldFollowUser: () => _cameraController.followUser,
      shouldFollowHeadingUp: () => _cameraController.followHeadingUp,
      followZoomProvider: () => _cameraController.cameraZoom,
      followTiltProvider: () => _cameraController.cameraTilt,
    );
  }

  Future<void> _hideUserLocation() async {
    await _userLocationController.hideUserLocation(
      controller: _mapSession.controller,
    );
  }

  Future<void> _flushPendingGpsData() async {
    await _userLocationController.flushPendingGpsData(
      controller: _mapSession.controller,
      isReady: () => _mapSession.isReadyForUserLocation,
      shouldFollowUser: () => _cameraController.followUser,
      shouldFollowHeadingUp: () => _cameraController.followHeadingUp,
      followZoomProvider: () => _cameraController.cameraZoom,
      followTiltProvider: () => _cameraController.cameraTilt,
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
    _cameraController.onCameraMove(cameraPosition);
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
    final double controlsTopOffset = widget.topPadding;

    return BlocListener<FlightScreenCubit, FlightScreenState>(
      listener: (context, state) {
        if (state is FlightScreenLoaded) {
          _selectedRegionOverlayController.updateRouteRegions(
            state.routeRegions,
          );
          _dayNightController.handleGpsUpdate(
            status: state.gps.status,
            data: state.gps.data,
          );
          final mapPosition = state.gps.mapPosition;
          if (mapPosition != null) {
            _updateUserLocation(mapPosition);
          } else {
            _hideUserLocation();
          }
        }
      },
      child: Stack(
        children: [
          Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              _cameraController.handleMapPointerDown();
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
              compassEnabled: false,
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
          FlightMapGpsBadgeOverlay(
            topOffset: controlsTopOffset,
            sunEventForecast: _dayNightController.sunEventForecast,
            onGpsHelpTap: widget.onGpsHelpTap,
          ),
          FlightMapControls(
            topOffset: controlsTopOffset + 4,
            visible:
                _cameraController.showControls || _cameraController.followUser,
            offlineMapStyle: _styleController.style,
            mapStyleLoading: _styleTransitionController.isLoading,
            is3D: _cameraController.is3D,
            followUser: _cameraController.followUser,
            showResetNorth: _cameraController.showResetNorth,
            mapBearingDegrees: _cameraController.mapBearingDegrees,
            onToggleMapStyle: _toggleMapStyle,
            onToggle3D: _toggle3D,
            onToggleFollowUser: _toggleUserFollow,
            onResetNorth: _resetNorth,
          ),
          FlightMapBottomStatusOverlay(
            onSelectedRegionChanged: _onGeoRegionSelectionChanged,
            onCheckInPressed: () => _checkInFlight(context),
          ),
          if (!_mapSession.isMapInitialized) const MapInitializingOverlay(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.removeListener(_onControllerChanged);
    _dayNightController.removeListener(_onControllerChanged);
    _styleController.removeListener(_onControllerChanged);
    _styleTransitionController.removeListener(_onControllerChanged);
    _mapSession.controller?.onSymbolTapped.remove(_onSymbolTapped);
    if (_featureTapListenerAttached) {
      _mapSession.controller?.onFeatureTapped.remove(_onFeatureTapped);
      _featureTapListenerAttached = false;
    }
    _cameraController.dispose();
    _dayNightController.dispose();
    _styleController.dispose();
    _styleTransitionController.dispose();
    _userLocationController.dispose();
    _mapSession.dispose();
    super.dispose();
  }

  Future<void> _checkInFlight(BuildContext context) async {
    final ok = await context.read<FlightScreenCubit>().checkInFlight();
    if (ok) {
      homeRefreshNotifier.value = true;
    }
    if (!context.mounted) {
      return;
    }

    final message = ok
        ? context.t.flight.upcoming.checkInSuccess
        : context.t.flight.upcoming.checkInError;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _resetNorth() async {
    await _cameraController.resetNorth(_mapSession.controller);
  }
}
