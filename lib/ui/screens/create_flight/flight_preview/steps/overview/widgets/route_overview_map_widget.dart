import 'dart:async';
import 'dart:math' show Point, atan2, cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/poi_wiki_preview.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/flight_route_map_layers.dart';
import 'package:flymap/ui/map/layers/latlon_utils.dart';
import 'package:flymap/ui/map/layers/poi_layer.dart';
import 'package:flymap/ui/map/map_style_safety.dart';
import 'package:flymap/ui/map/map_utils.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/utils/url_utils.dart';
import 'package:get_it/get_it.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:maplibre_gl/maplibre_gl.dart';

class RouteOverviewMapWidget extends StatefulWidget {
  const RouteOverviewMapWidget({
    required this.route,
    required this.flightInfo,
    required this.selectedRegion,
    required this.selectedAirport,
    required this.showWholeRoute,
    super.key,
  });

  final FlightRoute route;
  final FlightInfo flightInfo;
  final RouteRegion? selectedRegion;
  final Airport? selectedAirport;
  final bool showWholeRoute;

  @override
  State<RouteOverviewMapWidget> createState() => _RouteOverviewMapWidgetState();
}

class _RouteOverviewMapWidgetState extends State<RouteOverviewMapWidget> {
  static const String _primaryStyleUrl =
      '${UrlUtils.flymapTilesUrl}/styles/liberty';
  static const String _fallbackStyleUrl =
      '${UrlUtils.ofmTilesUrl}/styles/liberty';
  static const Duration _styleLoadTimeout = Duration(seconds: 8);

  static const String _selectedRegionSourceId =
      'route-overview-selected-region-source';
  static const String _selectedRegionFillLayerId =
      'route-overview-selected-region-fill';
  static const String _selectedRegionLineLayerId =
      'route-overview-selected-region-line';
  static const String _planeSourceId = 'route-overview-plane-source';
  static const String _planeLayerId = 'route-overview-plane-layer';
  static const String _planeImageId = 'route-overview-plane-blue-image';
  static const String _planeIconAssetPath =
      'assets/images/icons/plane_blue.png';
  static const double _regionPlaneEntryOffsetKm = 10.0;
  static const double _airportHeadingSampleKm = 10.0;
  static const String _routePathLayerId = 'flight-route-path-layer';
  static const String _regionHighlightColor = '#8B5CF6';
  static const double _wholeRouteBoundsPadding = 44;

  final Logger _logger = const Logger('RouteOverviewMapWidget');
  MapLibreMapController? _mapController;
  Timer? _styleFallbackTimer;
  bool _mapReady = false;
  bool _didFallbackToOpenFreeMap = false;
  String _styleUrl = _primaryStyleUrl;
  bool _routeLayersAdded = false;
  int _styleGeneration = 0;
  int _poiSignature = 0;
  String? _lastFocusedRegionQid;
  String? _lastFocusedAirportKey;
  bool _isPoiDialogVisible = false;
  bool _featureTapListenerAttached = false;
  static final Map<String, Uint8List> _assetBytesCache = {};

  late final AppAnalytics _analytics = GetIt.I.get<AppAnalytics>();

  late final _center = MapUtils.routeCenter(widget.route).toMapLatLon();

  void _onMapCreated(MapLibreMapController controller) {
    _invalidateStyleState();
    _mapController = controller;
    if (!_featureTapListenerAttached) {
      controller.onFeatureTapped.add(_onFeatureTapped);
      _featureTapListenerAttached = true;
    }
    setState(() {
      _mapReady = true;
    });
    _scheduleStyleFallbackIfNeeded();
  }

  void _onStyleLoaded() {
    _styleFallbackTimer?.cancel();
    _styleFallbackTimer = null;
    if (!_mapReady) return;

    final styleGeneration = ++_styleGeneration;
    _routeLayersAdded = false;
    _poiSignature = 0;

    Future.delayed(const Duration(milliseconds: 200), () async {
      if (!_isCurrentStyleGeneration(styleGeneration)) return;
      final controller = _mapController;
      if (controller == null) return;

      try {
        await FlightRouteMapLayers.add(
          controller: controller,
          route: widget.route,
        );
        _routeLayersAdded = true;
        await _syncPoiLayer(expectedStyleGeneration: styleGeneration);
        await _syncRegionLayers(expectedStyleGeneration: styleGeneration);
        await _syncPlaneLayer(expectedStyleGeneration: styleGeneration);
        await _focusOnSelection(expectedStyleGeneration: styleGeneration);
      } on PlatformException catch (error) {
        if (isStaleStylePlatformException(error)) {
          _logger.log('Skipping stale style route-overview update: $error');
          return;
        }
        _logger.error('Failed to update route overview style layers: $error');
      }
    });
  }

  void _scheduleStyleFallbackIfNeeded() {
    if (_didFallbackToOpenFreeMap || _styleUrl != _primaryStyleUrl) {
      return;
    }
    _styleFallbackTimer?.cancel();
    _styleFallbackTimer = Timer(_styleLoadTimeout, () {
      if (!mounted || _didFallbackToOpenFreeMap) return;
      _logger.error(
        'Primary style did not load within $_styleLoadTimeout, switching to OpenFreeMap fallback',
      );
      setState(() {
        _didFallbackToOpenFreeMap = true;
        _styleUrl = _fallbackStyleUrl;
      });
    });
  }

  @override
  void didUpdateWidget(covariant RouteOverviewMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final styleGeneration = _styleGeneration;
    if (oldWidget.flightInfo != widget.flightInfo) {
      unawaited(_syncPoiLayer(expectedStyleGeneration: styleGeneration));
    }
    final oldAirportKey = _airportFocusKey(oldWidget.selectedAirport);
    final nextAirportKey = _airportFocusKey(widget.selectedAirport);
    if (oldWidget.selectedRegion?.qid != widget.selectedRegion?.qid ||
        oldAirportKey != nextAirportKey ||
        oldWidget.showWholeRoute != widget.showWholeRoute) {
      unawaited(_syncRegionLayers(expectedStyleGeneration: styleGeneration));
      unawaited(_syncPlaneLayer(expectedStyleGeneration: styleGeneration));
      unawaited(_focusOnSelection(expectedStyleGeneration: styleGeneration));
    }
  }

  Future<void> _syncPoiLayer({required int expectedStyleGeneration}) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _mapController;
    if (!_routeLayersAdded || controller == null) {
      return;
    }

    final nextSignature = Object.hashAll(
      widget.flightInfo.poi.map(
        (poi) =>
            Object.hash(poi.qid, poi.latLon.latitude, poi.latLon.longitude),
      ),
    );
    if (_poiSignature == nextSignature) {
      return;
    }
    _poiSignature = nextSignature;

    try {
      await PoiLayer(poi: widget.flightInfo.poi).add(controller);
      // Re-apply plane after POI layer rebuild to keep plane above POI symbols.
      await _syncPlaneLayer(expectedStyleGeneration: expectedStyleGeneration);
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale style POI sync: $error');
        return;
      }
      _logger.error('Failed to sync POI layer: $error');
    }
  }

  void _onFeatureTapped(
    Point<double> point,
    LatLng _,
    String __,
    String layerId,
    Annotation? ___,
  ) {
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
      if (features.isEmpty || !mounted) return;
      await _showPoiDialogFromFeature(features.first);
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
    final storedPoi = qid.isNotEmpty
        ? widget.flightInfo.poi.where((p) => p.qid == qid).firstOrNull
        : null;
    final preloadedPreview = storedPoi == null
        ? null
        : PoiWikiPreview(
            qid: qid,
            title: storedPoi.name,
            summary: storedPoi.description,
            htmlContent: storedPoi.descriptionHtml,
            sourceUrl: storedPoi.wiki,
            languageCode: '',
          );
    await showPoiPreviewDialog(
      context: context,
      name: name,
      typeRaw: typeRaw,
      qid: qid,
      actionMode: PoiPreviewActionMode.openOnly,
      preloadedPreview: preloadedPreview,
    );
  }

  Map<dynamic, dynamic>? _extractFeatureProperties(dynamic feature) {
    if (feature is! Map) return null;
    final rawProperties = feature['properties'];
    if (rawProperties is Map) return rawProperties;
    return feature;
  }

  Future<void> _syncRegionLayers({required int expectedStyleGeneration}) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _mapController;
    if (!_routeLayersAdded || controller == null) return;

    final selectedFeature = widget.selectedRegion == null
        ? null
        : _toRegionFeature(widget.selectedRegion!);

    await _removeLayerIfExists(controller, _selectedRegionLineLayerId);
    await _removeLayerIfExists(controller, _selectedRegionFillLayerId);
    await _removeSourceIfExists(controller, _selectedRegionSourceId);

    if (selectedFeature != null) {
      await controller.addSource(
        _selectedRegionSourceId,
        GeojsonSourceProperties(
          data: {
            'type': 'FeatureCollection',
            'features': [selectedFeature],
          },
        ),
      );
      await controller.addLayer(
        _selectedRegionSourceId,
        _selectedRegionFillLayerId,
        FillLayerProperties(
          fillColor: _regionHighlightColor,
          fillOpacity: 0.28,
          fillOutlineColor: _regionHighlightColor,
        ),
        belowLayerId: _routePathLayerId,
      );
      await controller.addLineLayer(
        _selectedRegionSourceId,
        _selectedRegionLineLayerId,
        LineLayerProperties(
          lineColor: _regionHighlightColor,
          lineOpacity: 0.9,
          lineWidth: 2.3,
        ),
        belowLayerId: _routePathLayerId,
      );
    }
  }

  Future<void> _syncPlaneLayer({required int expectedStyleGeneration}) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _mapController;
    if (!_routeLayersAdded || controller == null) return;

    await _removeLayerIfExists(controller, _planeLayerId);
    await _removeSourceIfExists(controller, _planeSourceId);

    final placement = _currentPlanePlacement();
    if (placement == null) {
      return;
    }

    await _ensurePlaneImageRegistered(controller);
    await controller.addSource(
      _planeSourceId,
      GeojsonSourceProperties(
        data: {
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [
                  placement.point.longitude,
                  placement.point.latitude,
                ],
              },
              'properties': {'bearing': placement.bearingDeg},
            },
          ],
        },
      ),
    );
    await controller.addLayer(
      _planeSourceId,
      _planeLayerId,
      SymbolLayerProperties(
        iconImage: _planeImageId,
        iconSize: [
          'step',
          ['zoom'],
          0.42,
          4,
          0.48,
          7,
          0.54,
        ],
        iconRotate: ['get', 'bearing'],
        iconRotationAlignment: 'map',
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
    );
  }

  Future<void> _focusOnSelection({required int expectedStyleGeneration}) async {
    if (!_isCurrentStyleGeneration(expectedStyleGeneration)) return;
    final controller = _mapController;
    if (controller == null) return;

    if (widget.showWholeRoute) {
      await _focusOnWholeRoute(controller);
      _lastFocusedRegionQid = null;
      _lastFocusedAirportKey = null;
      return;
    }

    final selectedAirport = widget.selectedAirport;
    if (selectedAirport != null) {
      final airportKey = _airportFocusKey(selectedAirport);
      if (_lastFocusedAirportKey == airportKey) {
        return;
      }
      await _focusOnAirport(controller, selectedAirport);
      _lastFocusedAirportKey = airportKey;
      _lastFocusedRegionQid = null;
      return;
    }

    _lastFocusedAirportKey = null;
    final selected = widget.selectedRegion;
    if (selected == null) {
      await _focusOnWholeRoute(controller);
      _lastFocusedRegionQid = null;
      return;
    }
    if (_lastFocusedRegionQid == selected.qid) return;

    final routePoints = _routePoints();
    if (routePoints.length < 2) return;
    final routeDistanceKm = _routeLengthKm(routePoints);
    if (routeDistanceKm <= 0) return;

    final lengthInsideKm = selected.pathLengthInsideKm.isFinite
        ? selected.pathLengthInsideKm
        : 0.0;
    final pathCenterKm = (selected.pathFirstEncounterKm + (lengthInsideKm / 2))
        .clamp(0.0, routeDistanceKm);
    final targetPoint = _pointAtDistanceKm(routePoints, pathCenterKm);
    if (targetPoint == null) return;

    final zoom = _zoomForPathLengthKm(lengthInsideKm);

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(targetPoint.toMapLatLon(), zoom),
      );
      _lastFocusedRegionQid = selected.qid;
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale style region focus: $error');
        return;
      }
      _logger.error('Failed to focus selected region: $error');
    }
  }

  _PlanePlacement? _currentPlanePlacement() {
    if (widget.showWholeRoute) {
      return null;
    }
    final routePoints = _routePoints();
    if (routePoints.length < 2) return null;
    final routeDistanceKm = _routeLengthKm(routePoints);
    if (routeDistanceKm <= 0) return null;

    final selectedAirport = widget.selectedAirport;
    if (selectedAirport != null) {
      final airportPoint = selectedAirport.latLon;
      final isDeparture =
          selectedAirport.primaryCode == widget.route.departure.primaryCode;
      final sampleKm = _airportHeadingSampleKm.clamp(0.0, routeDistanceKm);
      final bearing = isDeparture
          ? _bearingDegForRouteWindow(
              routePoints: routePoints,
              routeDistanceKm: routeDistanceKm,
              fromKm: 0.0,
              toKm: sampleKm,
            )
          : _bearingDegForRouteWindow(
              routePoints: routePoints,
              routeDistanceKm: routeDistanceKm,
              fromKm: (routeDistanceKm - sampleKm).clamp(0.0, routeDistanceKm),
              toKm: routeDistanceKm,
            );
      return _PlanePlacement(point: airportPoint, bearingDeg: bearing);
    }

    final selectedRegion = widget.selectedRegion;
    if (selectedRegion == null) return null;
    final regionStartKm = selectedRegion.pathFirstEncounterKm.clamp(
      0.0,
      routeDistanceKm,
    );
    final regionEndKm =
        (selectedRegion.pathFirstEncounterKm +
                selectedRegion.pathLengthInsideKm)
            .clamp(0.0, routeDistanceKm);
    final targetKm = (regionStartKm + _regionPlaneEntryOffsetKm).clamp(
      regionStartKm,
      regionEndKm >= regionStartKm ? regionEndKm : regionStartKm,
    );
    final targetPoint = _pointAtDistanceKm(routePoints, targetKm);
    if (targetPoint == null) return null;

    // Use nearby points along the route to keep heading aligned with route flow.
    const headingSampleKm = 25.0;
    final back = _pointAtDistanceKm(
      routePoints,
      (targetKm - headingSampleKm).clamp(0.0, routeDistanceKm),
    );
    final fwd = _pointAtDistanceKm(
      routePoints,
      (targetKm + headingSampleKm).clamp(0.0, routeDistanceKm),
    );
    final bearing = (back == null || fwd == null)
        ? _bearingDegBetween(routePoints.first, routePoints.last)
        : _bearingDegBetween(back, fwd);
    return _PlanePlacement(point: targetPoint, bearingDeg: bearing);
  }

  Future<void> _focusOnAirport(
    MapLibreMapController controller,
    Airport airport,
  ) async {
    final zoom = _zoomForAirportCard(widget.route.distanceInKm);
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(airport.latLon.toMapLatLon(), zoom),
      );
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale style airport focus: $error');
        return;
      }
      _logger.error('Failed to focus airport: $error');
    }
  }

  Future<void> _focusOnWholeRoute(MapLibreMapController controller) async {
    final bounds = _overviewBounds();
    if (bounds == null) {
      final zoom = MapUtils.calculateZoomLevel(
        departure: widget.route.departure,
        arrival: widget.route.arrival,
      );
      final clampedZoom = (zoom.isFinite ? zoom : 1.0).toDouble();
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(_center, clampedZoom),
        );
      } on PlatformException catch (error) {
        if (isStaleStylePlatformException(error)) {
          _logger.log('Skipping stale style whole-route focus: $error');
          return;
        }
        _logger.error('Failed to focus whole route: $error');
      }
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: _wholeRouteBoundsPadding,
          top: _wholeRouteBoundsPadding,
          right: _wholeRouteBoundsPadding,
          bottom: _wholeRouteBoundsPadding,
        ),
      );
    } on PlatformException catch (error) {
      if (isStaleStylePlatformException(error)) {
        _logger.log('Skipping stale style whole-route focus: $error');
        return;
      }
      _logger.error('Failed to focus whole route: $error');
    }
  }

  List<ll.LatLng> _routePoints() {
    if (widget.route.waypoints.length >= 2) {
      return widget.route.waypointLatLngs;
    }
    return [widget.route.departure.latLon, widget.route.arrival.latLon];
  }

  double _routeLengthKm(List<ll.LatLng> points) {
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += MapUtils.distanceKm(
        departure: points[i],
        arrival: points[i + 1],
      );
    }
    return total;
  }

  ll.LatLng? _pointAtDistanceKm(List<ll.LatLng> points, double targetKm) {
    if (points.isEmpty) return null;
    if (points.length == 1) return points.first;
    if (targetKm <= 0) return points.first;

    var traversedKm = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segmentKm = MapUtils.distanceKm(departure: start, arrival: end);
      if (segmentKm <= 0) {
        continue;
      }

      final segmentEndKm = traversedKm + segmentKm;
      if (targetKm <= segmentEndKm || i == points.length - 2) {
        final localT = ((targetKm - traversedKm) / segmentKm).clamp(0.0, 1.0);
        return _interpolateLatLng(start, end, localT);
      }
      traversedKm = segmentEndKm;
    }
    return points.last;
  }

  ll.LatLng _interpolateLatLng(ll.LatLng start, ll.LatLng end, double t) {
    final lat = start.latitude + (end.latitude - start.latitude) * t;
    final lon = _interpolateLongitudeShortestPath(
      start.longitude,
      end.longitude,
      t,
    );
    return ll.LatLng(lat, lon);
  }

  double _bearingDegBetween(ll.LatLng from, ll.LatLng to) {
    final lat1 = from.latitude * (pi / 180.0);
    final lat2 = to.latitude * (pi / 180.0);
    final lon1 = from.longitude * (pi / 180.0);
    final lon2 = to.longitude * (pi / 180.0);
    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final deg = atan2(y, x) * (180.0 / pi);
    return (deg + 360.0) % 360.0;
  }

  double _bearingDegForRouteWindow({
    required List<ll.LatLng> routePoints,
    required double routeDistanceKm,
    required double fromKm,
    required double toKm,
  }) {
    final fromPoint = _pointAtDistanceKm(
      routePoints,
      fromKm.clamp(0.0, routeDistanceKm),
    );
    final toPoint = _pointAtDistanceKm(
      routePoints,
      toKm.clamp(0.0, routeDistanceKm),
    );
    if (fromPoint == null || toPoint == null) {
      return _bearingDegBetween(routePoints.first, routePoints.last);
    }
    if (fromPoint.latitude == toPoint.latitude &&
        fromPoint.longitude == toPoint.longitude) {
      return _bearingDegBetween(routePoints.first, routePoints.last);
    }
    return _bearingDegBetween(fromPoint, toPoint);
  }

  double _interpolateLongitudeShortestPath(
    double fromLon,
    double toLon,
    double t,
  ) {
    var delta = toLon - fromLon;
    if (delta > 180.0) {
      delta -= 360.0;
    } else if (delta < -180.0) {
      delta += 360.0;
    }
    final raw = fromLon + delta * t;
    return _normalizeLongitude(raw);
  }

  double _normalizeLongitude(double longitude) {
    var lon = longitude;
    while (lon > 180.0) {
      lon -= 360.0;
    }
    while (lon < -180.0) {
      lon += 360.0;
    }
    return lon;
  }

  LatLngBounds? _overviewBounds() {
    final allCorridorPoints = widget.route.effectiveCorridorPolygons
        .expand((ring) => ring)
        .toList(growable: false);
    final source = allCorridorPoints.isNotEmpty
        ? allCorridorPoints
        : _routePoints();
    if (source.isEmpty) {
      return null;
    }

    var minLat = source.first.latitude;
    var maxLat = source.first.latitude;
    var minLon = source.first.longitude;
    var maxLon = source.first.longitude;
    for (final point in source) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    const minSpan = 0.02;
    const paddingFactor = 0.16;
    final latSpan = (maxLat - minLat).abs();
    final lonSpan = (maxLon - minLon).abs();
    final paddedLatSpan = (latSpan * (1 + paddingFactor * 2)).clamp(
      minSpan,
      180.0,
    );
    final paddedLonSpan = (lonSpan * (1 + paddingFactor * 2)).clamp(
      minSpan,
      360.0,
    );
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;

    final paddedMinLat = (centerLat - paddedLatSpan / 2).clamp(-90.0, 90.0);
    final paddedMaxLat = (centerLat + paddedLatSpan / 2).clamp(-90.0, 90.0);
    final paddedMinLon = (centerLon - paddedLonSpan / 2).clamp(-180.0, 180.0);
    final paddedMaxLon = (centerLon + paddedLonSpan / 2).clamp(-180.0, 180.0);

    if (paddedMinLat >= paddedMaxLat || paddedMinLon >= paddedMaxLon) {
      return null;
    }
    return LatLngBounds(
      southwest: LatLng(paddedMinLat, paddedMinLon),
      northeast: LatLng(paddedMaxLat, paddedMaxLon),
    );
  }

  double _zoomForPathLengthKm(double pathLengthKm) {
    if (!pathLengthKm.isFinite || pathLengthKm <= 0) return 5.8;
    if (pathLengthKm > 3500) return 1;
    if (pathLengthKm > 2200) return 1.4;
    if (pathLengthKm > 1400) return 2.0;
    if (pathLengthKm > 900) return 2.4;
    if (pathLengthKm > 550) return 3;
    if (pathLengthKm > 320) return 3.6;
    if (pathLengthKm > 180) return 4;
    if (pathLengthKm > 100) return 4.5;
    if (pathLengthKm > 55) return 5;
    if (pathLengthKm > 25) return 6;
    return 6.8;
  }

  double _zoomForAirportCard(double routeDistanceKm) {
    if (!routeDistanceKm.isFinite || routeDistanceKm <= 0) return 6.2;
    if (routeDistanceKm > 7000) return 4.6;
    if (routeDistanceKm > 4000) return 5.0;
    if (routeDistanceKm > 2000) return 5.4;
    if (routeDistanceKm > 900) return 5.8;
    return 6.2;
  }

  String? _airportFocusKey(Airport? airport) {
    if (airport == null) {
      return null;
    }
    return '${airport.primaryCode}:${airport.latLon.latitude}:${airport.latLon.longitude}';
  }

  Map<String, dynamic> _toRegionFeature(RouteRegion region) {
    return {
      'type': 'Feature',
      'properties': {'qid': region.qid, 'name': region.name},
      'geometry': region.geometry.geoJson,
    };
  }

  Future<void> _removeLayerIfExists(
    MapLibreMapController controller,
    String layerId,
  ) async {
    try {
      await controller.removeLayer(layerId);
    } catch (_) {}
  }

  Future<void> _removeSourceIfExists(
    MapLibreMapController controller,
    String sourceId,
  ) async {
    try {
      await controller.removeSource(sourceId);
    } catch (_) {}
  }

  bool _isCurrentStyleGeneration(int generation) {
    return mounted && generation == _styleGeneration;
  }

  void _invalidateStyleState() {
    _styleGeneration++;
    _routeLayersAdded = false;
    _poiSignature = 0;
    _lastFocusedRegionQid = null;
    _lastFocusedAirportKey = null;
  }

  Future<void> _ensurePlaneImageRegistered(
    MapLibreMapController controller,
  ) async {
    final bytes = await _loadAssetBytes(_planeIconAssetPath);
    if (bytes == null) return;
    try {
      await controller.addImage(_planeImageId, bytes);
    } catch (error) {
      if (!_isImageAlreadyRegisteredError(error)) {
        _logger.error(
          'Failed to register plane image "$_planeImageId": $error',
        );
      }
    }
  }

  Future<Uint8List?> _loadAssetBytes(String assetPath) async {
    final cached = _assetBytesCache[assetPath];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      _assetBytesCache[assetPath] = bytes;
      return bytes;
    } catch (error) {
      _logger.error('Failed to load asset "$assetPath": $error');
      return null;
    }
  }

  bool _isImageAlreadyRegisteredError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('already exists') ||
        text.contains('image already added') ||
        text.contains('image with name');
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _overviewBounds();
    final initialZoom = bounds == null
        ? (MapUtils.calculateZoomLevel(
                departure: widget.route.departure,
                arrival: widget.route.arrival,
              ).isFinite
              ? MapUtils.calculateZoomLevel(
                  departure: widget.route.departure,
                  arrival: widget.route.arrival,
                )
              : 1.0)
        : _zoomForBounds(bounds);

    return MapLibreMap(
      key: ValueKey<String>(_styleUrl),
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(target: _center, zoom: initialZoom),
      trackCameraPosition: true,
      styleString: _styleUrl,
      compassViewPosition: CompassViewPosition.bottomRight,
      compassViewMargins: const Point(10, 10),
      onStyleLoadedCallback: _onStyleLoaded,
    );
  }

  @override
  void dispose() {
    _styleFallbackTimer?.cancel();
    _styleFallbackTimer = null;
    if (_featureTapListenerAttached) {
      _mapController?.onFeatureTapped.remove(_onFeatureTapped);
      _featureTapListenerAttached = false;
    }
    _mapController = null;
    _mapReady = false;
    _routeLayersAdded = false;
    _styleGeneration++;
    _lastFocusedRegionQid = null;
    _lastFocusedAirportKey = null;
    super.dispose();
  }

  double _zoomForBounds(LatLngBounds bounds) {
    final latSpan = (bounds.northeast.latitude - bounds.southwest.latitude)
        .abs();
    final lonSpan = (bounds.northeast.longitude - bounds.southwest.longitude)
        .abs();
    final maxSpan = latSpan > lonSpan ? latSpan : lonSpan;
    if (!maxSpan.isFinite || maxSpan <= 0) return 2.0;
    if (maxSpan > 120) return 0.8;
    if (maxSpan > 80) return 1.2;
    if (maxSpan > 45) return 1.7;
    if (maxSpan > 30) return 2.2;
    if (maxSpan > 20) return 2.8;
    if (maxSpan > 12) return 3.4;
    if (maxSpan > 8) return 4.0;
    if (maxSpan > 5) return 4.6;
    if (maxSpan > 3) return 5.2;
    if (maxSpan > 1.8) return 5.8;
    if (maxSpan > 1.0) return 6.4;
    if (maxSpan > 0.5) return 7.2;
    return 8.0;
  }
}

class _PlanePlacement {
  const _PlanePlacement({required this.point, required this.bearingDeg});

  final ll.LatLng point;
  final double bearingDeg;
}
