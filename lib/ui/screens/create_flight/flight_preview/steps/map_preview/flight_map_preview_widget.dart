import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/flight_route_map_layers.dart';
import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/poi_layer.dart';
import 'package:flymap/ui/map/map_style_safety.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/usecase/get_poi_wiki_preview_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapPreviewWidget extends StatefulWidget {
  final FlightRoute flightRoute;
  final FlightInfo flightInfo;
  final double minZoom;
  final double maxZoom;

  const FlightMapPreviewWidget({
    super.key,
    required this.flightRoute,
    required this.flightInfo,
    required this.minZoom,
    required this.maxZoom,
  });

  @override
  State<FlightMapPreviewWidget> createState() => _FlightMapPreviewWidgetState();
}

class _FlightMapPreviewWidgetState extends State<FlightMapPreviewWidget> {
  final Logger _logger = const Logger('FlightMapPreviewWidget');
  MapLibreMapController? _mapController;
  bool _mapReady = false;
  late final FlightRoute route = widget.flightRoute;
  bool _routeLayersAdded = false;
  int _styleGeneration = 0;
  int _poiSignature = 0;
  bool _isPoiDialogVisible = false;
  bool _featureTapListenerAttached = false;
  late final AppAnalytics _analytics = GetIt.I.get<AppAnalytics>();
  late final GetPoiWikiPreviewUseCase _wikiPreviewUseCase = GetIt.I
      .get<GetPoiWikiPreviewUseCase>();

  late final LatLng _center = MapUtils.routeCenter(
    widget.flightRoute,
  ).toMapLatLon();

  void _onMapCreated(MapLibreMapController controller) {
    _invalidateStyleState();
    _mapController = controller;
    if (!_featureTapListenerAttached) {
      controller.onFeatureTapped.add(_onFeatureTapped);
      _featureTapListenerAttached = true;
      _logger.log('Attached onFeatureTapped listener');
    }
    setState(() {
      _mapReady = true;
    });
    unawaited(_clampCameraZoomToBounds());
  }

  void _onStyleLoaded() {
    if (!_mapReady) return;
    final styleGeneration = ++_styleGeneration;
    _routeLayersAdded = false;
    _poiSignature = 0;

    // Add a small delay to ensure style is fully loaded.
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!_isCurrentStyleGeneration(styleGeneration)) return;
      final controller = _mapController;
      if (controller == null) return;

      try {
        await _addFlightMapLayers(controller);
        if (!_isCurrentStyleGeneration(styleGeneration)) return;
        await _syncPoiLayer(expectedStyleGeneration: styleGeneration);
      } on PlatformException catch (error) {
        if (isStaleStylePlatformException(error)) {
          _logger.log('Skipping stale style map preview update: $error');
          return;
        }
        _logger.error('Failed to update map preview style layers: $error');
        return;
      }
    });
  }

  Future<void> _addFlightMapLayers(MapLibreMapController controller) async {
    await FlightRouteMapLayers.add(controller: controller, route: route);
    _routeLayersAdded = true;
  }

  @override
  void didUpdateWidget(covariant FlightMapPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flightInfo != widget.flightInfo) {
      unawaited(_syncPoiLayer(expectedStyleGeneration: _styleGeneration));
    }
    final zoomBoundsChanged =
        oldWidget.minZoom != widget.minZoom ||
        oldWidget.maxZoom != widget.maxZoom;
    if (zoomBoundsChanged) {
      unawaited(_clampCameraZoomToBounds());
    }
  }

  Future<void> _clampCameraZoomToBounds() async {
    final controller = _mapController;
    if (controller == null) return;

    final currentZoom = controller.cameraPosition?.zoom;
    if (currentZoom == null || !currentZoom.isFinite) return;

    final minZoom = widget.minZoom;
    final maxZoom = widget.maxZoom;
    final clampedZoom = currentZoom.clamp(minZoom, maxZoom).toDouble();
    if ((clampedZoom - currentZoom).abs() < 0.001) return;

    await controller.animateCamera(CameraUpdate.zoomTo(clampedZoom));
  }

  Future<void> _syncPoiLayer({required int expectedStyleGeneration}) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _mapController;
    if (!_routeLayersAdded || controller == null) {
      _logger.log(
        'Skip POI sync routeLayersAdded=$_routeLayersAdded mapController=${controller != null}',
      );
      return;
    }

    final nextSignature = Object.hashAll(
      widget.flightInfo.poi.map((poi) => poi.name),
    );
    if (_poiSignature == nextSignature) {
      _logger.log(
        'Skip POI sync unchanged signature count=${widget.flightInfo.poi.length}',
      );
      return;
    }
    _poiSignature = nextSignature;

    final sample = widget.flightInfo.poi
        .take(5)
        .map((e) => '${e.name}/${e.type}')
        .join(', ');
    _logger.log(
      'Applying POI layer count=${widget.flightInfo.poi.length}'
      '${sample.isEmpty ? '' : ' sample=[$sample]'}',
    );
    try {
      await PoiLayer(poi: widget.flightInfo.poi).add(controller);
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale style POI sync: $error');
        return;
      }
      _logger.error('Failed to sync POI layer: $error');
    }
  }

  bool _isCurrentStyleGeneration(int generation) {
    return mounted && generation == _styleGeneration;
  }

  void _invalidateStyleState() {
    _styleGeneration++;
    _routeLayersAdded = false;
    _poiSignature = 0;
  }

  void _onFeatureTapped(
    Point<double> point,
    LatLng _,
    String id,
    String layerId,
    Annotation? __,
  ) {
    _logger.log(
      'onFeatureTapped layerId=$layerId id=$id x=${point.x.toStringAsFixed(1)} y=${point.y.toStringAsFixed(1)}',
    );
    if (layerId != PoiLayer.iconsLayerId &&
        layerId != PoiLayer.circlesLayerId &&
        layerId != PoiLayer.labelsLayerId) {
      return;
    }
    unawaited(_handlePoiTapAtPoint(point));
  }

  Future<void> _handlePoiTapAtPoint(Point<double> point) async {
    final controller = _mapController;
    if (controller == null || !_routeLayersAdded || _isPoiDialogVisible) {
      return;
    }

    try {
      _logger.log(
        'Handle POI tap at x=${point.x.toStringAsFixed(1)} y=${point.y.toStringAsFixed(1)}',
      );
      var features = await controller.queryRenderedFeatures(point, const [
        PoiLayer.iconsLayerId,
        PoiLayer.circlesLayerId,
        PoiLayer.labelsLayerId,
      ], null);
      if (features.isEmpty) {
        final tapRect = Rect.fromCenter(
          center: Offset(point.x, point.y),
          width: 56,
          height: 56,
        );
        features = await controller.queryRenderedFeaturesInRect(tapRect, const [
          PoiLayer.iconsLayerId,
          PoiLayer.circlesLayerId,
          PoiLayer.labelsLayerId,
        ], null);
      }
      _logger.log('POI hit-test features=${features.length}');
      if (features.isEmpty || !mounted) return;

      final firstFeature = features.first;
      await _showPoiDialogFromFeature(firstFeature);
    } catch (e) {
      _logger.error('Failed to show POI dialog on feature tap: $e');
    } finally {
      _isPoiDialogVisible = false;
    }
  }

  Future<void> _showPoiDialogFromFeature(dynamic feature) async {
    final properties = _extractFeatureProperties(feature);
    final name = (properties?['name'] ?? '').toString().trim();
    final typeRaw = (properties?['type'] ?? '').toString().trim();
    final qid = (properties?['qid'] ?? '').toString().trim();
    _logger.log(
      'POI feature resolved name="$name" type="$typeRaw" qid="$qid" rawType=${feature.runtimeType}',
    );
    if (name.isEmpty || !mounted) return;

    unawaited(
      _analytics.log(
        PoiMarkerTappedEvent(
          source: PoiMarkerTapSource.mapPreview,
          poiType: typeRaw,
        ),
      ),
    );

    _isPoiDialogVisible = true;
    await showPoiPreviewDialog(
      context: context,
      name: name,
      typeRaw: typeRaw,
      qid: qid,
      actionMode: PoiPreviewActionMode.openOnly,
      wikiPreviewUseCase: _wikiPreviewUseCase,
    );
  }

  Map<dynamic, dynamic>? _extractFeatureProperties(dynamic feature) {
    if (feature is! Map) return null;
    final rawProperties = feature['properties'];
    if (rawProperties is Map) return rawProperties;
    return feature;
  }

  @override
  Widget build(BuildContext context) {
    double zoom = MapUtils.calculateZoomLevel(
      departure: route.departure,
      arrival: route.arrival,
    );
    final initialZoom = (zoom.isFinite ? zoom : 1.0)
        .clamp(widget.minZoom, widget.maxZoom)
        .toDouble();
    return MapLibreMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(target: _center, zoom: initialZoom),
      minMaxZoomPreference: MinMaxZoomPreference(
        widget.minZoom,
        widget.maxZoom,
      ),
      trackCameraPosition: true,
      styleString: "https://tiles.openfreemap.org/styles/liberty",
      compassViewPosition: CompassViewPosition.bottomRight,
      compassViewMargins: const Point(16, 16),
      onStyleLoadedCallback: _onStyleLoaded,
    );
  }

  @override
  void dispose() {
    if (_featureTapListenerAttached) {
      _mapController?.onFeatureTapped.remove(_onFeatureTapped);
      _featureTapListenerAttached = false;
    }
    _mapController = null;
    _mapReady = false;
    _routeLayersAdded = false;
    _styleGeneration++;
    super.dispose();
  }
}
