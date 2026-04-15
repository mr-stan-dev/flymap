import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/ui/map/layers/poi_layer.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/usecase/get_poi_wiki_preview_use_case.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class FlightMapPoiController {
  FlightMapPoiController({
    required Logger logger,
    required Flight flight,
    required AppAnalytics analytics,
    required GetPoiWikiPreviewUseCase wikiPreviewUseCase,
    required ConnectivityChecker connectivityChecker,
  }) : _logger = logger,
       _flight = flight,
       _analytics = analytics,
       _wikiPreviewUseCase = wikiPreviewUseCase,
       _connectivityChecker = connectivityChecker;

  final Logger _logger;
  final Flight _flight;
  final AppAnalytics _analytics;
  final GetPoiWikiPreviewUseCase _wikiPreviewUseCase;
  final ConnectivityChecker _connectivityChecker;

  bool _isPoiDialogVisible = false;

  bool isPoiLayer(String layerId) {
    return layerId == PoiLayer.iconsLayerId ||
        layerId == PoiLayer.circlesLayerId ||
        layerId == PoiLayer.labelsLayerId;
  }

  Future<void> handlePoiTapAtPoint(
    Point<double> point, {
    required BuildContext context,
    required MapLibreMapController? controller,
    required bool routeLayersAdded,
  }) async {
    if (controller == null || !routeLayersAdded || _isPoiDialogVisible) return;
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
      if (features.isEmpty || !context.mounted) return;
      await _showPoiDialogFromFeature(features.first, context: context);
    } catch (error) {
      _logger.error('Failed to handle POI tap: $error');
    } finally {
      _isPoiDialogVisible = false;
    }
  }

  Future<void> _showPoiDialogFromFeature(
    dynamic feature, {
    required BuildContext context,
  }) async {
    if (!context.mounted) return;
    final props = feature is Map ? (feature['properties'] ?? feature) : null;
    if (props is! Map) return;
    final name = (props['name'] ?? '').toString().trim();
    final typeRaw = (props['type'] ?? '').toString().trim();
    final qid = (props['qid'] ?? '').toString().trim();
    if (name.isEmpty) return;

    unawaited(
      _analytics.log(
        PoiMarkerTappedEvent(
          source: PoiMarkerTapSource.flightMap,
          poiType: typeRaw,
        ),
      ),
    );

    final storedPoi = qid.isNotEmpty
        ? _flight.info.poi.where((p) => p.qid == qid).firstOrNull
        : null;
    final preloaded = (storedPoi != null && storedPoi.description.isNotEmpty)
        ? PoiWikiPreview(
            qid: qid,
            title: storedPoi.name,
            summary: storedPoi.description,
            htmlContent: storedPoi.descriptionHtml,
            sourceUrl: storedPoi.wiki,
            languageCode: '',
          )
        : null;

    _isPoiDialogVisible = true;
    final hasInternet = await _connectivityChecker.hasInternetConnectivity();
    if (!context.mounted) return;
    await showPoiPreviewDialog(
      context: context,
      name: name,
      typeRaw: typeRaw,
      qid: qid,
      actionMode: hasInternet
          ? PoiPreviewActionMode.openOnly
          : PoiPreviewActionMode.none,
      wikiPreviewUseCase: _wikiPreviewUseCase,
      preloadedPreview: preloaded,
    );
  }
}
