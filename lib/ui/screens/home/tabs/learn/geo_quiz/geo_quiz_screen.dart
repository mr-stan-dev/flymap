import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:country_flags/country_flags.dart' as country_flags;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/geo_quiz_summary_localization.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class GeoQuizScreen extends StatelessWidget {
  const GeoQuizScreen({required this.summary, super.key});

  final GeoQuizSummary summary;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GeoQuizCubit>(
      create: (_) => GetIt.I<GeoQuizCubit>(
        param1: summary,
        param2: context.read<SubscriptionCubit>().state.isPro,
      )..load(),
      child: _GeoQuizScaffold(summary: summary),
    );
  }
}

class _GeoQuizScaffold extends StatelessWidget {
  const _GeoQuizScaffold({required this.summary});

  final GeoQuizSummary summary;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(localizedGeoQuizTitle(context.t, summary)),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.92),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                context.read<GeoQuizCubit>().reset();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'reset',
                child: Text(context.t.learn.geoQuiz.reset),
              ),
            ],
          ),
        ],
      ),
      body: BlocBuilder<GeoQuizCubit, GeoQuizState>(
        builder: (context, state) {
          switch (state) {
            case GeoQuizLoading():
              return LoadingStateView(title: context.t.learn.geoQuiz.loading);
            case GeoQuizError(:final message):
              return ErrorStateView(
                title: context.t.learn.geoQuiz.failedToLoadQuiz,
                message: message,
                retryLabel: context.t.common.retry,
                onRetry: () => context.read<GeoQuizCubit>().load(),
              );
            case GeoQuizLoaded():
              return _GeoQuizLoadedView(state: state);
          }
        },
      ),
    );
  }
}

class _GeoQuizLoadedView extends StatefulWidget {
  const _GeoQuizLoadedView({required this.state});

  final GeoQuizLoaded state;

  @override
  State<_GeoQuizLoadedView> createState() => _GeoQuizLoadedViewState();
}

class _GeoQuizLoadedViewState extends State<_GeoQuizLoadedView> {
  Timer? _focusAfterKeyboardTimer;
  Timer? _wrongFeedbackTimer;
  bool _showCorrectOverlay = false;
  bool _allowMapFocus = true;
  String _correctLabel = '';
  GeoQuizRegion? _correctRegion;
  String? _correctDescription;
  bool _correctDescriptionLoading = false;
  int _correctOverlayGeneration = 0;

  @override
  void didUpdateWidget(covariant _GeoQuizLoadedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isComplete &&
        !widget.state.isComplete &&
        !_showCorrectOverlay) {
      _allowMapFocus = true;
    }
    final feedback = widget.state.feedback;
    if (feedback != oldWidget.state.feedback && feedback?.isCorrect == true) {
      _startCorrectTransition(feedback!, _newlySolvedRegion(oldWidget.state));
    } else if (feedback != oldWidget.state.feedback &&
        feedback?.isCorrect == false) {
      _startWrongFeedbackTimer();
    }
  }

  GeoQuizRegion? _newlySolvedRegion(GeoQuizLoaded oldState) {
    final oldSolvedIds = oldState.progress.solvedRegionIds;
    for (final region in widget.state.regions) {
      if (widget.state.progress.solvedRegionIds.contains(region.id) &&
          !oldSolvedIds.contains(region.id)) {
        return region;
      }
    }
    return oldState.currentRegion;
  }

  void _startCorrectTransition(
    GeoQuizAnswerFeedback feedback,
    GeoQuizRegion? region,
  ) {
    _focusAfterKeyboardTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    final generation = ++_correctOverlayGeneration;
    _correctLabel = feedback.label;
    _correctRegion = region;
    _correctDescription = null;
    _correctDescriptionLoading = region != null;
    _showCorrectOverlay = true;
    _allowMapFocus = false;
    if (region != null) {
      unawaited(_loadCorrectDescription(region, generation));
    }
  }

  Future<void> _loadCorrectDescription(
    GeoQuizRegion region,
    int generation,
  ) async {
    final description = await context
        .read<GeoQuizCubit>()
        .loadRegionDescription(region.id);
    if (!mounted ||
        generation != _correctOverlayGeneration ||
        !_showCorrectOverlay) {
      return;
    }
    setState(() {
      _correctDescription = description;
      _correctDescriptionLoading = false;
    });
  }

  void _completeCorrectTransition() {
    if (!_showCorrectOverlay) return;
    _correctOverlayGeneration += 1;
    setState(() {
      _showCorrectOverlay = false;
      _correctDescriptionLoading = false;
    });
    context.read<GeoQuizCubit>().clearFeedback();
    if (!widget.state.isComplete) {
      _focusAfterKeyboardTimer = Timer(const Duration(milliseconds: 260), () {
        if (!mounted) return;
        setState(() {
          _allowMapFocus = true;
        });
      });
    }
  }

  void _startWrongFeedbackTimer() {
    _wrongFeedbackTimer?.cancel();
    _wrongFeedbackTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final feedback = widget.state.feedback;
      if (feedback?.isCorrect == false) {
        context.read<GeoQuizCubit>().clearFeedback();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final geoJsonAssetPath = state.summary.geoJsonAssetPath;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = keyboardInset > 0;
    return Stack(
      children: [
        Positioned.fill(
          child: geoJsonAssetPath == null
              ? _GeoQuizMapPlaceholder(state: state)
              : _GeoQuizVectorMap(
                  state: state,
                  countriesGeoJsonAssetPath: geoJsonAssetPath,
                  focusEnabled: _allowMapFocus,
                ),
        ),
        if (kDebugMode && state.currentRegion != null)
          _DebugCorrectAnswerLabel(
            label: context.read<GeoQuizCubit>().regionLabel(
              state.currentRegion!,
            ),
          ),
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _showCorrectOverlay
                ? _CorrectAnswerOverlay(
                    key: ValueKey(_correctRegion?.id ?? _correctLabel),
                    region: _correctRegion,
                    label: _correctLabel,
                    description: _correctDescription,
                    descriptionLoading: _correctDescriptionLoading,
                    isFinalAnswer: state.isComplete,
                    onContinue: _completeCorrectTransition,
                  )
                : state.isComplete
                ? _GeoQuizCompletionOverlay(state: state)
                : const SizedBox.shrink(),
          ),
        ),
        if (!state.isComplete && !_showCorrectOverlay)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(
                bottom: isKeyboardOpen ? keyboardInset : 12,
              ),
              child: SafeArea(
                minimum: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  isKeyboardOpen ? 16 : 24,
                ),
                child: _GeoQuizAnswerPanel(
                  state: state,
                  isCompact: isKeyboardOpen,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _correctOverlayGeneration += 1;
    _focusAfterKeyboardTimer?.cancel();
    _wrongFeedbackTimer?.cancel();
    super.dispose();
  }
}

class _GeoQuizMapPlaceholder extends StatelessWidget {
  const _GeoQuizMapPlaceholder({required this.state});

  final GeoQuizLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = DsSemanticColors.success(context);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFD8ECF5)),
      child: CustomPaint(
        painter: _GeoQuizMapPlaceholderPainter(
          landColor: theme.colorScheme.surfaceContainerLowest,
          borderColor: theme.colorScheme.outline.withValues(alpha: 0.58),
          solvedColor: success.withValues(alpha: 0.42),
          solvedBorderColor: success,
          solvedFraction: state.progressFraction,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 76),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    context.t.learn.geoQuiz.mapPlaceholder,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DebugCorrectAnswerLabel extends StatelessWidget {
  const _DebugCorrectAnswerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      left: 12,
      top: MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeoQuizVectorMap extends StatefulWidget {
  const _GeoQuizVectorMap({
    required this.state,
    required this.countriesGeoJsonAssetPath,
    required this.focusEnabled,
  });

  final GeoQuizLoaded state;
  final String countriesGeoJsonAssetPath;
  final bool focusEnabled;

  @override
  State<_GeoQuizVectorMap> createState() => _GeoQuizVectorMapState();
}

class _GeoQuizVectorMapState extends State<_GeoQuizVectorMap> {
  static const _cameraZoomOutDuration = Duration(milliseconds: 450);
  static const _cameraFocusDuration = Duration(milliseconds: 1100);
  static const _initialCameraFocusDuration = Duration(milliseconds: 800);
  static const _styleString =
      '{"version":8,"sources":{},"layers":[{"id":"background","type":"background","paint":{"background-color":"#D8ECF5"}}]}';
  static const _landAssetPath = 'assets/data/ne_50m_land.geojson';
  static const _boundariesAssetPath =
      'assets/data/geo_quiz/countries/country_boundaries.geojson';
  static const _landSourceId = 'geo-quiz-land-source';
  static const _landLayerId = 'geo-quiz-land-layer';
  static const _landOutlineLayerId = 'geo-quiz-land-outline-layer';
  static const _countriesSourceId = 'geo-quiz-countries-source';
  static const _boundariesSourceId = 'geo-quiz-boundaries-source';
  static const _countryBorderLayerId = 'geo-quiz-country-border-layer';
  static const _solvedSourceId = 'geo-quiz-solved-source';
  static const _solvedLineLayerId = 'geo-quiz-solved-line-layer';
  static const _solvedPulseSourceId = 'geo-quiz-solved-pulse-source';
  static const _solvedPersistentLayerId = 'geo-quiz-solved-persistent-layer';
  static const _solvedBlinkSourceId = 'geo-quiz-solved-blink-source';
  static const _solvedPulseLayerId = 'geo-quiz-solved-pulse-layer';
  static const _solvedPulseLineLayerId = 'geo-quiz-solved-pulse-line-layer';
  static const _currentSourceId = 'geo-quiz-current-source';
  static const _currentFillLayerId = 'geo-quiz-current-fill-layer';
  static const _currentLineLayerId = 'geo-quiz-current-line-layer';

  MapLibreMapController? _controller;
  Map<String, dynamic>? _countriesGeoJson;
  bool _styleReady = false;
  bool _sourcesAdded = false;
  bool _mapLoading = true;
  String? _errorMessage;
  String? _lastFocusedRegionId;
  int _cameraTransitionGeneration = 0;
  Timer? _solvedPulseTimer;
  int _solvedPulseStep = 0;

  @override
  void didUpdateWidget(covariant _GeoQuizVectorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countriesGeoJsonAssetPath !=
        widget.countriesGeoJsonAssetPath) {
      _countriesGeoJson = null;
      setState(() {
        _sourcesAdded = false;
        _mapLoading = true;
        _errorMessage = null;
        _lastFocusedRegionId = null;
      });
      unawaited(_syncSourcesAndLayers());
      return;
    }
    final progressChanged =
        oldWidget.state.progress.solvedRegionIds !=
        widget.state.progress.solvedRegionIds;
    final currentRegionChanged =
        oldWidget.state.currentRegionId != widget.state.currentRegionId;
    if (progressChanged) {
      final solvedRegionId = _newlySolvedRegionId(oldWidget.state);
      unawaited(_handleSolvedProgressChanged(solvedRegionId));
    }
    if (currentRegionChanged && widget.focusEnabled) {
      unawaited(_syncCurrentSource());
      unawaited(_focusCurrentRegion());
    } else if (currentRegionChanged) {
      unawaited(_syncCurrentSource());
    } else if (!oldWidget.focusEnabled && widget.focusEnabled) {
      unawaited(_syncCurrentSource());
      unawaited(_focusCurrentRegion(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return Stack(
      children: [
        MapLibreMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(52, 11),
            zoom: 3.15,
          ),
          compassEnabled: false,
          rotateGesturesEnabled: false,
          styleString: _styleString,
          onMapClick: _handleMapClick,
          onMapCreated: (controller) {
            _controller = controller;
          },
          onStyleLoadedCallback: () {
            _styleReady = true;
            unawaited(_syncSourcesAndLayers());
          },
        ),
        if (errorMessage != null)
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 76),
                child: _MapStatusPill(message: errorMessage),
              ),
            ),
          ),
        if (errorMessage == null && _mapLoading)
          const Positioned.fill(child: _MapLoadingState()),
      ],
    );
  }

  Future<void> _syncSourcesAndLayers() async {
    final controller = _controller;
    if (!_styleReady || controller == null || _sourcesAdded) return;

    try {
      final landGeoJson = await _loadGeoJson(_landAssetPath);
      final boundariesGeoJson = await _loadGeoJson(_boundariesAssetPath);
      _countriesGeoJson ??= await _loadGeoJson(
        widget.countriesGeoJsonAssetPath,
      );

      await controller.addSource(
        _landSourceId,
        GeojsonSourceProperties(data: landGeoJson),
      );
      await controller.addLayer(
        _landSourceId,
        _landLayerId,
        const FillLayerProperties(fillColor: '#F4F2EE', fillOpacity: 1.0),
        enableInteraction: false,
      );
      await controller.addLayer(
        _landSourceId,
        _landOutlineLayerId,
        const LineLayerProperties(
          lineColor: '#9C9C9C',
          lineOpacity: 0.62,
          lineWidth: 0.65,
        ),
        enableInteraction: false,
      );
      await controller.addSource(
        _countriesSourceId,
        GeojsonSourceProperties(data: _countriesGeoJson!),
      );
      await controller.addSource(
        _boundariesSourceId,
        GeojsonSourceProperties(data: boundariesGeoJson),
      );
      await controller.addLayer(
        _boundariesSourceId,
        _countryBorderLayerId,
        const LineLayerProperties(
          lineColor: '#9C9C9C',
          lineOpacity: 0.62,
          lineWidth: 0.65,
        ),
        enableInteraction: false,
      );
      await controller.addGeoJsonSource(
        _solvedSourceId,
        _solvedFeatureCollection(),
      );
      await controller.addLayer(
        _solvedSourceId,
        _solvedLineLayerId,
        const LineLayerProperties(
          lineColor: '#15803D',
          lineOpacity: 0.84,
          lineWidth: 1.35,
        ),
        enableInteraction: false,
      );
      await controller.addGeoJsonSource(
        _solvedPulseSourceId,
        _solvedFeatureCollection(),
      );
      await controller.addLayer(
        _solvedPulseSourceId,
        _solvedPersistentLayerId,
        const FillLayerProperties(fillColor: '#22C55E', fillOpacity: 0.56),
        enableInteraction: false,
      );
      await controller.addGeoJsonSource(
        _solvedBlinkSourceId,
        _emptyFeatureCollection(),
      );
      await controller.addLayer(
        _solvedBlinkSourceId,
        _solvedPulseLayerId,
        const FillLayerProperties(fillColor: '#22C55E', fillOpacity: 0.0),
        enableInteraction: false,
      );
      await controller.addLayer(
        _solvedBlinkSourceId,
        _solvedPulseLineLayerId,
        const LineLayerProperties(
          lineColor: '#15803D',
          lineOpacity: 0.0,
          lineWidth: 2.2,
        ),
        enableInteraction: false,
      );
      await controller.addGeoJsonSource(
        _currentSourceId,
        _currentFeatureCollection(),
      );
      await controller.addLayer(
        _currentSourceId,
        _currentFillLayerId,
        const FillLayerProperties(fillColor: '#A855F7', fillOpacity: 0.68),
        enableInteraction: false,
      );
      await controller.addLayer(
        _currentSourceId,
        _currentLineLayerId,
        const LineLayerProperties(
          lineColor: '#5B21B6',
          lineOpacity: 0.90,
          lineWidth: 1.8,
        ),
        enableInteraction: false,
      );
      _sourcesAdded = true;
      await _syncSolvedSource();
      await _syncCurrentSource();
      _markMapLoaded();
      if (widget.focusEnabled) {
        unawaited(_focusCurrentRegion());
      }
    } on PlatformException catch (error) {
      _setError('Map data failed to load');
      debugPrint('Geo Quiz map platform error: $error');
    } catch (error) {
      _setError('Map data failed to load');
      debugPrint('Geo Quiz map error: $error');
    }
  }

  Future<void> _handleMapClick(Point<double> _, LatLng coordinate) async {
    if (!_sourcesAdded) return;
    final regionId = _solvedRegionIdAt(coordinate);
    if (regionId == null || !mounted) return;
    final region = _regionForId(regionId);
    if (region == null) return;
    await _showRegionDetails(region);
  }

  Future<void> _showRegionDetails(GeoQuizRegion region) async {
    final cubit = context.read<GeoQuizCubit>();
    final label = cubit.regionLabel(region);
    final description = await cubit.loadRegionDescription(region.id);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _GeoQuizRegionDetailsDialog(
        region: region,
        title: label,
        description: description,
      ),
    );
  }

  String? _newlySolvedRegionId(GeoQuizLoaded oldState) {
    final solvedIds = widget.state.progress.solvedRegionIds;
    final oldSolvedIds = oldState.progress.solvedRegionIds;
    final oldCurrentRegionId = oldState.currentRegionId;
    if (oldCurrentRegionId != null &&
        solvedIds.contains(oldCurrentRegionId) &&
        !oldSolvedIds.contains(oldCurrentRegionId)) {
      return oldCurrentRegionId;
    }
    for (final id in solvedIds) {
      if (!oldSolvedIds.contains(id)) return id;
    }
    return null;
  }

  Future<void> _handleSolvedProgressChanged(String? solvedRegionId) async {
    await _syncSolvedSource();
    if (solvedRegionId != null) {
      await _startSolvedPulse(solvedRegionId);
    }
  }

  Future<void> _startSolvedPulse(String regionId) async {
    final controller = _controller;
    if (!_styleReady || controller == null || !_sourcesAdded) return;
    final feature = _featureForId(regionId);
    if (feature == null) return;

    _solvedPulseTimer?.cancel();
    _solvedPulseStep = 0;

    try {
      await controller.setGeoJsonSource(_solvedBlinkSourceId, <String, dynamic>{
        'type': 'FeatureCollection',
        'features': <dynamic>[feature],
      });
      await _setSolvedPulseOpacity(0.44);
    } on PlatformException catch (error) {
      debugPrint('Geo Quiz solved-pulse start failed: $error');
      return;
    }

    _solvedPulseTimer = Timer.periodic(const Duration(milliseconds: 220), (
      timer,
    ) {
      _solvedPulseStep += 1;
      final opacity = _solvedPulseStep.isOdd ? 0.0 : 0.44;
      unawaited(_setSolvedPulseOpacity(opacity));
      if (_solvedPulseStep >= 6) {
        timer.cancel();
        unawaited(_clearSolvedPulse());
      }
    });
  }

  Future<void> _setSolvedPulseOpacity(double opacity) async {
    final controller = _controller;
    if (!_styleReady || controller == null || !_sourcesAdded) return;
    try {
      await controller.setLayerProperties(
        _solvedPulseLayerId,
        FillLayerProperties(fillColor: '#22C55E', fillOpacity: opacity),
      );
      await controller.setLayerProperties(
        _solvedPulseLineLayerId,
        LineLayerProperties(
          lineColor: '#15803D',
          lineOpacity: opacity > 0 ? 1.0 : 0.0,
          lineWidth: 2.2,
        ),
      );
    } on PlatformException catch (error) {
      debugPrint('Geo Quiz solved-pulse opacity update failed: $error');
    }
  }

  Future<void> _clearSolvedPulse() async {
    final controller = _controller;
    if (!_styleReady || controller == null || !_sourcesAdded) return;
    try {
      await _setSolvedPulseOpacity(0.0);
      await controller.setGeoJsonSource(
        _solvedBlinkSourceId,
        _emptyFeatureCollection(),
      );
      await _syncSolvedSource();
    } on PlatformException catch (error) {
      debugPrint('Geo Quiz solved-pulse clear failed: $error');
    }
  }

  Future<void> _syncSolvedSource() async {
    final controller = _controller;
    if (!_styleReady || controller == null || !_sourcesAdded) return;

    try {
      final solvedFeatures = _solvedFeatureCollection();
      await controller.setGeoJsonSource(_solvedSourceId, solvedFeatures);
      await controller.setGeoJsonSource(_solvedPulseSourceId, solvedFeatures);
    } on PlatformException catch (error) {
      debugPrint('Geo Quiz solved-source update failed: $error');
    }
  }

  Future<void> _syncCurrentSource() async {
    final controller = _controller;
    if (!_styleReady || controller == null || !_sourcesAdded) return;

    try {
      await controller.setGeoJsonSource(
        _currentSourceId,
        _currentFeatureCollection(),
      );
    } on PlatformException catch (error) {
      debugPrint('Geo Quiz current-source update failed: $error');
    }
  }

  Future<void> _focusCurrentRegion({bool force = false}) async {
    final controller = _controller;
    if (!_styleReady || controller == null || !_sourcesAdded) return;
    if (!widget.focusEnabled && !force) return;

    final currentRegionId = widget.state.currentRegionId;
    if (currentRegionId == null ||
        (!force && currentRegionId == _lastFocusedRegionId)) {
      return;
    }
    final focusBounds = _boundsForFeature(_featureForId(currentRegionId));
    if (focusBounds == null) return;

    final previousRegionId = _lastFocusedRegionId;
    _lastFocusedRegionId = currentRegionId;
    final transitionGeneration = ++_cameraTransitionGeneration;
    final padding = _focusPaddingForViewport(focusBounds.maxSpan);
    try {
      if (previousRegionId != null && previousRegionId != currentRegionId) {
        final cameraPosition = await controller.queryCameraPosition();
        if (!_isCurrentCameraTransition(
          transitionGeneration,
          currentRegionId,
        )) {
          return;
        }
        if (cameraPosition != null) {
          final zoomedOutLevel = max(1.7, cameraPosition.zoom - 1.1);
          await _runCameraStage(
            controller.animateCamera(
              CameraUpdate.zoomTo(zoomedOutLevel),
              duration: _cameraZoomOutDuration,
            ),
            _cameraZoomOutDuration,
          );
          if (!_isCurrentCameraTransition(
            transitionGeneration,
            currentRegionId,
          )) {
            return;
          }
        }
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          focusBounds.bounds,
          left: padding.left,
          top: padding.top,
          right: padding.right,
          bottom: padding.bottom,
        ),
        duration: previousRegionId == null
            ? _initialCameraFocusDuration
            : _cameraFocusDuration,
      );
    } on PlatformException catch (error) {
      debugPrint('Geo Quiz current-region focus failed: $error');
    }
  }

  Future<void> _runCameraStage(
    Future<bool?> animation,
    Duration duration,
  ) async {
    final stopwatch = Stopwatch()..start();
    await animation;
    stopwatch.stop();
    final remaining = duration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  bool _isCurrentCameraTransition(int generation, String regionId) {
    return mounted &&
        generation == _cameraTransitionGeneration &&
        widget.state.currentRegionId == regionId;
  }

  EdgeInsets _focusPaddingForViewport(double maxSpan) {
    final height = MediaQuery.maybeSizeOf(context)?.height ?? 800;
    if (maxSpan >= 45) {
      return EdgeInsets.fromLTRB(
        40,
        (height * 0.08).clamp(64.0, 104.0),
        40,
        (height * 0.26).clamp(180.0, 300.0),
      );
    }
    return EdgeInsets.fromLTRB(
      48,
      (height * 0.08).clamp(72.0, 112.0),
      48,
      (height * 0.42).clamp(300.0, 460.0),
    );
  }

  Future<Map<String, dynamic>> _loadGeoJson(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('GeoJSON root must be an object.');
    }
    return decoded.cast<String, dynamic>();
  }

  Map<String, dynamic> _solvedFeatureCollection() {
    final countries = _countriesGeoJson;
    if (countries == null) {
      return const <String, dynamic>{
        'type': 'FeatureCollection',
        'features': <dynamic>[],
      };
    }
    final features = countries['features'];
    if (features is! List) {
      return const <String, dynamic>{
        'type': 'FeatureCollection',
        'features': <dynamic>[],
      };
    }

    final solvedIds = widget.state.progress.solvedRegionIds;
    final solvedFeatures = <dynamic>[];
    for (final feature in features) {
      final id = _featureId(feature);
      if (id != null && solvedIds.contains(id)) {
        solvedFeatures.add(feature);
      }
    }
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': solvedFeatures,
    };
  }

  Map<String, dynamic> _currentFeatureCollection() {
    if (!widget.focusEnabled) return _emptyFeatureCollection();
    final currentRegionId = widget.state.currentRegionId;
    if (currentRegionId == null) return _emptyFeatureCollection();
    final feature = _featureForId(currentRegionId);
    if (feature == null) return _emptyFeatureCollection();
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <dynamic>[feature],
    };
  }

  Map<String, dynamic> _emptyFeatureCollection() {
    return const <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <dynamic>[],
    };
  }

  dynamic _featureForId(String regionId) {
    final countries = _countriesGeoJson;
    if (countries == null) return null;
    final features = countries['features'];
    if (features is! List) return null;

    for (final feature in features) {
      final id = _featureId(feature);
      if (id == regionId) return feature;
    }
    return null;
  }

  GeoQuizRegion? _regionForId(String regionId) {
    for (final region in widget.state.regions) {
      if (region.id == regionId) return region;
    }
    return null;
  }

  String? _solvedRegionIdAt(LatLng coordinate) {
    final features = _countriesGeoJson?['features'];
    if (features is! List) return null;
    final solvedIds = widget.state.progress.solvedRegionIds;
    for (final feature in features) {
      final regionId = _featureId(feature);
      if (regionId == null || !solvedIds.contains(regionId)) continue;
      if (_featureContainsCoordinate(feature, coordinate)) return regionId;
    }
    return null;
  }

  bool _featureContainsCoordinate(dynamic feature, LatLng coordinate) {
    if (feature is! Map) return false;
    final geometry = feature['geometry'];
    if (geometry is! Map) return false;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List) return false;

    if (geometry['type'] == 'Polygon') {
      return _polygonContainsCoordinate(coordinates, coordinate);
    }
    if (geometry['type'] == 'MultiPolygon') {
      for (final polygon in coordinates) {
        if (polygon is List &&
            _polygonContainsCoordinate(polygon, coordinate)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _polygonContainsCoordinate(List<dynamic> rings, LatLng coordinate) {
    if (rings.isEmpty || rings.first is! List) return false;
    if (!_ringContainsCoordinate(rings.first as List, coordinate)) return false;
    for (final hole in rings.skip(1)) {
      if (hole is List && _ringContainsCoordinate(hole, coordinate)) {
        return false;
      }
    }
    return true;
  }

  bool _ringContainsCoordinate(List<dynamic> ring, LatLng coordinate) {
    if (ring.length < 3) return false;
    var inside = false;
    var previous = ring.length - 1;
    for (var current = 0; current < ring.length; current++) {
      final currentPoint = ring[current];
      final previousPoint = ring[previous];
      if (currentPoint is! List ||
          currentPoint.length < 2 ||
          currentPoint[0] is! num ||
          currentPoint[1] is! num ||
          previousPoint is! List ||
          previousPoint.length < 2 ||
          previousPoint[0] is! num ||
          previousPoint[1] is! num) {
        previous = current;
        continue;
      }

      final currentLon = _longitudeNear(
        (currentPoint[0] as num).toDouble(),
        coordinate.longitude,
      );
      final previousLon = _longitudeNear(
        (previousPoint[0] as num).toDouble(),
        coordinate.longitude,
      );
      final currentLat = (currentPoint[1] as num).toDouble();
      final previousLat = (previousPoint[1] as num).toDouble();
      final intersects =
          ((currentLat > coordinate.latitude) !=
              (previousLat > coordinate.latitude)) &&
          (coordinate.longitude <
              (previousLon - currentLon) *
                      (coordinate.latitude - currentLat) /
                      (previousLat - currentLat) +
                  currentLon);
      if (intersects) inside = !inside;
      previous = current;
    }
    return inside;
  }

  double _longitudeNear(double longitude, double reference) {
    var result = longitude;
    while (result - reference > 180) {
      result -= 360;
    }
    while (result - reference < -180) {
      result += 360;
    }
    return result;
  }

  _GeoQuizFeatureBounds? _boundsForFeature(dynamic feature) {
    if (feature is! Map) return null;
    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final points = <LatLng>[];
    _collectGeoJsonPositions(_focusCoordinates(geometry), points);
    if (points.isEmpty) return null;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    final rawLongitudes = <double>[];
    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      rawLongitudes.add(point.longitude);
    }
    var (:minLon, :maxLon) = _minimalLongitudeWindow(rawLongitudes);

    const minSpan = 2.4;
    final latSpan = (maxLat - minLat).abs();
    final lonSpan = (maxLon - minLon).abs();
    final maxSpan = max(latSpan, lonSpan);
    final surroundingContextFactor = _surroundingContextFactor(maxSpan);
    final centerLat = (minLat + maxLat) / 2;
    final centerLon = (minLon + maxLon) / 2;
    final focusLatSpan = (latSpan * surroundingContextFactor).clamp(
      minSpan,
      180.0,
    );
    final focusLonSpan = (lonSpan * surroundingContextFactor).clamp(
      minSpan,
      360.0,
    );
    minLat = (centerLat - focusLatSpan / 2).clamp(-90.0, 90.0).toDouble();
    maxLat = (centerLat + focusLatSpan / 2).clamp(-90.0, 90.0).toDouble();
    minLon = (centerLon - focusLonSpan / 2).clamp(-180.0, 180.0).toDouble();
    maxLon = (centerLon + focusLonSpan / 2).clamp(-180.0, 180.0).toDouble();
    if (minLat >= maxLat || minLon >= maxLon) return null;

    return _GeoQuizFeatureBounds(
      bounds: LatLngBounds(
        southwest: LatLng(minLat, minLon),
        northeast: LatLng(maxLat, maxLon),
      ),
      maxSpan: maxSpan,
    );
  }

  dynamic _focusCoordinates(Map<dynamic, dynamic> geometry) {
    final coordinates = geometry['coordinates'];
    if (geometry['type'] != 'MultiPolygon' || coordinates is! List) {
      return coordinates;
    }

    dynamic largestPolygon;
    var largestArea = -1.0;
    for (final polygon in coordinates) {
      final area = _polygonArea(polygon);
      if (area > largestArea) {
        largestArea = area;
        largestPolygon = polygon;
      }
    }
    return largestPolygon ?? coordinates;
  }

  double _polygonArea(dynamic polygon) {
    if (polygon is! List || polygon.isEmpty) return 0;
    final outerRing = polygon.first;
    if (outerRing is! List || outerRing.length < 3) return 0;

    var area = 0.0;
    for (var index = 0; index < outerRing.length; index++) {
      final current = outerRing[index];
      final next = outerRing[(index + 1) % outerRing.length];
      if (current is! List ||
          current.length < 2 ||
          current[0] is! num ||
          current[1] is! num ||
          next is! List ||
          next.length < 2 ||
          next[0] is! num ||
          next[1] is! num) {
        continue;
      }
      area +=
          (current[0] as num).toDouble() * (next[1] as num).toDouble() -
          (next[0] as num).toDouble() * (current[1] as num).toDouble();
    }
    return area.abs() / 2;
  }

  double _surroundingContextFactor(double maxSpan) {
    if (maxSpan >= 80) return 1.08;
    if (maxSpan >= 45) return 1.16;
    if (maxSpan >= 25) return 1.35;
    if (maxSpan >= 10) return 1.65;
    return 2.25;
  }

  ({double minLon, double maxLon}) _minimalLongitudeWindow(
    List<double> rawLongitudes,
  ) {
    if (rawLongitudes.isEmpty) {
      return (minLon: -180.0, maxLon: 180.0);
    }
    final normalized =
        rawLongitudes.map((value) => value < 0 ? value + 360.0 : value).toList()
          ..sort();
    if (normalized.length == 1) {
      final longitude = normalized.single > 180
          ? normalized.single - 360
          : normalized.single;
      return (minLon: longitude, maxLon: longitude);
    }

    var largestGap = -1.0;
    var cutIndex = 0;
    for (var index = 0; index < normalized.length; index++) {
      final current = normalized[index];
      final next = index == normalized.length - 1
          ? normalized.first + 360.0
          : normalized[index + 1];
      final gap = next - current;
      if (gap > largestGap) {
        largestGap = gap;
        cutIndex = index;
      }
    }

    var minLon = normalized[(cutIndex + 1) % normalized.length];
    var maxLon = normalized[cutIndex];
    if (minLon > maxLon) {
      maxLon += 360.0;
    }
    while (minLon > 180.0) {
      minLon -= 360.0;
      maxLon -= 360.0;
    }
    return (minLon: minLon, maxLon: maxLon);
  }

  void _collectGeoJsonPositions(dynamic node, List<LatLng> points) {
    if (node is! List) return;
    if (node.length >= 2 && node[0] is num && node[1] is num) {
      points.add(
        LatLng((node[1] as num).toDouble(), (node[0] as num).toDouble()),
      );
      return;
    }
    for (final child in node) {
      _collectGeoJsonPositions(child, points);
    }
  }

  String? _featureId(dynamic feature) {
    if (feature is! Map) return null;
    final directId = feature['id']?.toString().trim();
    if (directId != null && directId.isNotEmpty) return directId;
    final properties = feature['properties'];
    if (properties is! Map) return null;
    final propertyId = properties['id']?.toString().trim();
    if (propertyId != null && propertyId.isNotEmpty) return propertyId;
    return null;
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _mapLoading = false;
    });
  }

  void _markMapLoaded() {
    if (!mounted) return;
    setState(() {
      _sourcesAdded = true;
      _mapLoading = false;
    });
  }

  @override
  void dispose() {
    _cameraTransitionGeneration += 1;
    _solvedPulseTimer?.cancel();
    super.dispose();
  }
}

class _GeoQuizFeatureBounds {
  const _GeoQuizFeatureBounds({required this.bounds, required this.maxSpan});

  final LatLngBounds bounds;
  final double maxSpan;
}

class _MapLoadingState extends StatelessWidget {
  const _MapLoadingState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IgnorePointer(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 148,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t.common.loading,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStatusPill extends StatelessWidget {
  const _MapStatusPill({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          message,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CorrectAnswerOverlay extends StatefulWidget {
  const _CorrectAnswerOverlay({
    required this.region,
    required this.label,
    required this.description,
    required this.descriptionLoading,
    required this.isFinalAnswer,
    required this.onContinue,
    super.key,
  });

  final GeoQuizRegion? region;
  final String label;
  final String? description;
  final bool descriptionLoading;
  final bool isFinalAnswer;
  final VoidCallback onContinue;

  @override
  State<_CorrectAnswerOverlay> createState() => _CorrectAnswerOverlayState();
}

class _CorrectAnswerOverlayState extends State<_CorrectAnswerOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _autoContinueDuration = Duration(seconds: 5);

  late final AnimationController _countdown = AnimationController(
    vsync: this,
    duration: _autoContinueDuration,
  );
  bool _paused = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _countdown.addStatusListener(_handleCountdownStatus);
    if (!widget.isFinalAnswer) {
      _countdown.forward();
    }
  }

  void _handleCountdownStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _continue();
    }
  }

  void _continue() {
    if (_completed) return;
    _completed = true;
    widget.onContinue();
  }

  void _pause() {
    if (widget.isFinalAnswer || _paused || _completed) return;
    _countdown.stop(canceled: false);
    setState(() {
      _paused = true;
    });
  }

  void _resume() {
    if (widget.isFinalAnswer || !_paused || _completed) return;
    setState(() {
      _paused = false;
    });
    _countdown.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = DsSemanticColors.success(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withValues(alpha: 0.18),
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.72,
                ),
                child: Material(
                  key: const Key('geoQuizCorrectOverlay'),
                  color: theme.colorScheme.surface,
                  elevation: 18,
                  shadowColor: Colors.black.withValues(alpha: 0.26),
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: success,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.t.learn.geoQuiz.correct,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: success,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _GeoQuizCountryHeader(
                          countryCode: widget.region?.countryCode,
                          title: widget.label,
                        ),
                        const SizedBox(height: 16),
                        Flexible(
                          child: Listener(
                            onPointerDown: (_) => _pause(),
                            child: _GeoQuizCountryDescription(
                              description: widget.description,
                              loading: widget.descriptionLoading,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (widget.isFinalAnswer)
                          PrimaryButton(
                            label: context.t.learn.geoQuiz.finish,
                            trailingIcon: Icons.check_rounded,
                            expand: false,
                            onPressed: _continue,
                          )
                        else
                          Row(
                            children: [
                              AnimatedBuilder(
                                animation: _countdown,
                                builder: (context, _) {
                                  final remainingSeconds =
                                      (_autoContinueDuration.inSeconds *
                                              (1 - _countdown.value))
                                          .ceil()
                                          .clamp(0, 5);
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _CountdownToggle(
                                        progress: 1 - _countdown.value,
                                        paused: _paused,
                                        onPressed: _paused ? _resume : _pause,
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 22,
                                        child: Text(
                                          '$remainingSeconds',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const Spacer(),
                              SecondaryButton(
                                label: context.t.learn.geoQuiz.next,
                                trailingIcon: Icons.arrow_forward_rounded,
                                compact: true,
                                expand: false,
                                onPressed: _continue,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdown.removeStatusListener(_handleCountdownStatus);
    _countdown.dispose();
    super.dispose();
  }
}

class _CountdownToggle extends StatelessWidget {
  const _CountdownToggle({
    required this.progress,
    required this.paused,
    required this.onPressed,
  });

  final double progress;
  final bool paused;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final success = DsSemanticColors.success(context);
    final tooltip = paused
        ? context.t.learn.geoQuiz.resume
        : context.t.learn.geoQuiz.pause;
    return SizedBox.square(
      dimension: 44,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(3),
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: success,
            ),
          ),
          IconButton(
            key: const Key('geoQuizCorrectCountdownToggle'),
            tooltip: tooltip,
            onPressed: onPressed,
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }
}

class _GeoQuizCompletionOverlay extends StatelessWidget {
  const _GeoQuizCompletionOverlay({required this.state});

  final GeoQuizLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = DsSemanticColors.success(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: theme.colorScheme.surface.withValues(alpha: 0.96),
            elevation: 16,
            shadowColor: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Icon(
                        Icons.verified_rounded,
                        color: success,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t.learn.geoQuiz.completeTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.t.learn.geoQuiz.completeMessage(
                      total: state.totalCount,
                      quiz: localizedGeoQuizTitle(context.t, state.summary),
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: context.t.learn.geoQuiz.backToQuizzes,
                    leadingIcon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: context.t.learn.geoQuiz.playAgain,
                    leadingIcon: Icons.refresh,
                    onPressed: context.read<GeoQuizCubit>().reset,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GeoQuizRegionDetailsDialog extends StatelessWidget {
  const _GeoQuizRegionDetailsDialog({
    required this.region,
    required this.title,
    required this.description,
  });

  final GeoQuizRegion region;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: _GeoQuizCountryHeader(
        countryCode: region.countryCode,
        title: title,
      ),
      content: _GeoQuizCountryDescription(
        description: description,
        loading: false,
      ),
      actions: [
        SecondaryButton(
          label: context.t.common.ok,
          compact: true,
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class _GeoQuizCountryHeader extends StatelessWidget {
  const _GeoQuizCountryHeader({required this.countryCode, required this.title});

  final String? countryCode;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: _CountryCodeFlag(countryCode: countryCode, size: 42),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryCodeFlag extends StatelessWidget {
  const _CountryCodeFlag({required this.countryCode, required this.size});

  final String? countryCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalizedCode = countryCode?.trim();
    if (normalizedCode != null && normalizedCode.length == 2) {
      return SizedBox(
        width: size,
        height: size,
        child: country_flags.CountryFlag.fromCountryCode(
          normalizedCode,
          width: size,
          height: size,
          shape: country_flags.Circle(),
        ),
      );
    }
    final theme = Theme.of(context);
    return Icon(Icons.public, size: size, color: theme.colorScheme.primary);
  }
}

class _GeoQuizCountryDescription extends StatelessWidget {
  const _GeoQuizCountryDescription({
    required this.description,
    required this.loading,
  });

  final String? description;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }
    final text = description?.trim();
    return SingleChildScrollView(
      child: SelectionArea(
        child: Text(
          text == null || text.isEmpty
              ? context.t.learn.geoQuiz.descriptionUnavailable
              : text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _GeoQuizAnswerPanel extends StatefulWidget {
  const _GeoQuizAnswerPanel({required this.state, required this.isCompact});

  final GeoQuizLoaded state;
  final bool isCompact;

  @override
  State<_GeoQuizAnswerPanel> createState() => _GeoQuizAnswerPanelState();
}

class _GeoQuizAnswerPanelState extends State<_GeoQuizAnswerPanel> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.query,
  );

  Future<void> _openHintDialog() async {
    final region = widget.state.currentRegion;
    if (region == null) return;
    final answer = context.read<GeoQuizCubit>().regionLabel(region);
    await showDialog<void>(
      context: context,
      builder: (context) => _GeoQuizHintDialog(answer: answer),
    );
  }

  @override
  void didUpdateWidget(covariant _GeoQuizAnswerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.state.query) {
      _controller.text = widget.state.query;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = widget.isCompact;
    return Material(
      color: theme.colorScheme.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.24),
      borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 10 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.state.suggestions.isNotEmpty) ...[
              _SuggestionsList(suggestions: widget.state.suggestions),
              SizedBox(height: isCompact ? 8 : 10),
            ],
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child:
                  widget.state.feedback == null ||
                      widget.state.feedback!.isCorrect
                  ? const SizedBox.shrink()
                  : Padding(
                      key: ValueKey(widget.state.feedback),
                      padding: EdgeInsets.only(bottom: isCompact ? 8 : 10),
                      child: _AnswerFeedbackBanner(
                        feedback: widget.state.feedback!,
                        isCompact: isCompact,
                      ),
                    ),
            ),
            TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: context.read<GeoQuizCubit>().updateQuery,
              onSubmitted: (_) => context.read<GeoQuizCubit>().submitQuery(),
              decoration: InputDecoration(
                isDense: isCompact,
                contentPadding: isCompact
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                    : null,
                hintText: context.t.learn.geoQuiz.countryHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          context.read<GeoQuizCubit>().updateQuery('');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                ),
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    context.t.learn.geoQuiz.nextCount(
                      next: widget.state.nextIndex,
                      total: widget.state.totalCount,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _GeoQuizPanelActionButton(
                    key: const Key('geoQuizHintButton'),
                    icon: Icons.lightbulb_outline,
                    tooltip: context.t.learn.geoQuiz.hintTitle,
                    onPressed: widget.state.currentRegion == null
                        ? null
                        : _openHintDialog,
                  ),
                  const SizedBox(width: 8),
                  _GeoQuizPanelActionButton(
                    icon: Icons.skip_next,
                    tooltip: context.t.learn.geoQuiz.next,
                    onPressed: widget.state.currentRegionId == null
                        ? null
                        : context.read<GeoQuizCubit>().skipCurrentRegion,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 9,
                  value: widget.state.progressFraction,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DsSemanticColors.success(context),
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _GeoQuizPanelActionButton extends StatelessWidget {
  const _GeoQuizPanelActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 40,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.72),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            shape: const StadiumBorder(),
          ),
          onPressed: onPressed,
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _GeoQuizHintDialog extends StatefulWidget {
  const _GeoQuizHintDialog({required this.answer});

  final String answer;

  @override
  State<_GeoQuizHintDialog> createState() => _GeoQuizHintDialogState();
}

class _GeoQuizHintDialogState extends State<_GeoQuizHintDialog> {
  static const _revealDuration = Duration(seconds: 3);
  static const _hintTileWidth = 34.0;
  static const _hintTileHeight = 44.0;

  final Set<int> _revealedIndices = <int>{};
  int? _revealingIndex;

  bool _isRevealableCharacter(String character) {
    final codeUnit = character.codeUnitAt(0);
    final isUppercaseLatin = codeUnit >= 65 && codeUnit <= 90;
    final isLowercaseLatin = codeUnit >= 97 && codeUnit <= 122;
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    return isUppercaseLatin || isLowercaseLatin || isDigit;
  }

  void _startReveal(int index) {
    if (_revealingIndex != null || _revealedIndices.contains(index)) return;
    setState(() {
      _revealingIndex = index;
    });
  }

  void _finishReveal(int index) {
    if (!mounted || _revealingIndex != index) return;
    setState(() {
      _revealingIndex = null;
      _revealedIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final characters = widget.answer.characters.toList(growable: false);
    return AlertDialog(
      key: const Key('geoQuizHintDialog'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      title: Text(
        context.t.learn.geoQuiz.hintTitle,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.learn.geoQuiz.hintSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (var index = 0; index < characters.length; index++)
                  _buildHintCharacterTile(
                    context,
                    character: characters[index],
                    index: index,
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          label: context.t.common.ok,
          compact: true,
          expand: false,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildHintCharacterTile(
    BuildContext context, {
    required String character,
    required int index,
  }) {
    final theme = Theme.of(context);
    if (character == ' ') {
      return const SizedBox(width: 10, height: 44);
    }
    final shouldReveal = _isRevealableCharacter(character);
    if (!shouldReveal) {
      return SizedBox(
        height: 44,
        child: Center(
          child: Text(
            character,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    final isRevealed = _revealedIndices.contains(index);
    final isRevealing = _revealingIndex == index;
    final isEnabled = !isRevealed && !isRevealing && _revealingIndex == null;
    final borderColor = isRevealed || isRevealing
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withValues(alpha: 0.28);
    final baseColor = isRevealed
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final placeholderColor = theme.colorScheme.onSurfaceVariant.withValues(
      alpha: isRevealing ? 0.3 : 0.45,
    );

    return SizedBox(
      key: ValueKey('geoQuizHintTile.$index'),
      width: _hintTileWidth,
      height: _hintTileHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isEnabled ? () => _startReveal(index) : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isRevealing)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('hintReveal.$index'),
                      duration: _revealDuration,
                      tween: Tween(begin: 0, end: 1),
                      onEnd: () => _finishReveal(index),
                      builder: (context, value, child) {
                        final fillHeight = _hintTileHeight * value;
                        final scannerAlignment = Alignment(0, -1 + (2 * value));
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: FractionallySizedBox(
                                heightFactor: value,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.18,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: fillHeight,
                              child: ClipRect(
                                child: OverflowBox(
                                  minWidth: _hintTileWidth,
                                  maxWidth: _hintTileWidth,
                                  minHeight: _hintTileHeight,
                                  maxHeight: _hintTileHeight,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: _hintTileWidth,
                                    height: _hintTileHeight,
                                    child: Center(
                                      child: Text(
                                        character.toUpperCase(),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: scannerAlignment,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0,
                                        ),
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.55,
                                        ),
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.9,
                                        ),
                                        theme.colorScheme.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.28),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(
                                    height: 6,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  if (!isRevealed)
                    Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: isRevealing ? 0 : 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: placeholderColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const SizedBox(width: 14, height: 4),
                        ),
                      ),
                    ),
                  Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: isRevealed
                          ? 1
                          : isRevealing
                          ? 0
                          : 0,
                      child: Text(
                        character.toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerFeedbackBanner extends StatelessWidget {
  const _AnswerFeedbackBanner({
    required this.feedback,
    required this.isCompact,
  });

  final GeoQuizAnswerFeedback feedback;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = feedback.isCorrect;
    final color = isCorrect
        ? DsSemanticColors.success(context)
        : theme.colorScheme.error;
    final background = color.withValues(alpha: 0.10);
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final title = isCorrect
        ? context.t.learn.geoQuiz.correct
        : context.t.learn.geoQuiz.wrong;
    final message = feedback.label.trim().isEmpty
        ? title
        : '$title · ${feedback.label}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isCompact ? 7 : 10,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: isCompact ? 19 : 22),
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: isCompact ? 13 : null,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.suggestions});

  final List<GeoQuizAnswerSuggestion> suggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return ActionChip(
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            avatar: _SuggestionLeadingIcon(suggestion: suggestion),
            label: Text(
              suggestion.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.72),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            onPressed: () {
              context.read<GeoQuizCubit>().acceptSuggestion(suggestion);
            },
          );
        },
      ),
    );
  }
}

class _SuggestionLeadingIcon extends StatelessWidget {
  const _SuggestionLeadingIcon({required this.suggestion});

  final GeoQuizAnswerSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final countryCode = suggestion.countryCode?.trim().toUpperCase();
    if (countryCode != null && countryCode.isNotEmpty) {
      return SizedBox(
        width: 18,
        height: 18,
        child: _CountryCodeFlag(countryCode: countryCode, size: 18),
      );
    }
    final regionType = RouteRegionType.fromApiValue(
      suggestion.regionType ?? 'unknown',
    );
    final assetPath = regionType.assetImagePath;
    final theme = Theme.of(context);
    if (assetPath != null) {
      return ClipOval(
        child: SizedBox(
          width: 18,
          height: 18,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Icon(
              Icons.public,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Icon(
      Icons.public,
      size: 18,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

class _GeoQuizMapPlaceholderPainter extends CustomPainter {
  const _GeoQuizMapPlaceholderPainter({
    required this.landColor,
    required this.borderColor,
    required this.solvedColor,
    required this.solvedBorderColor,
    required this.solvedFraction,
  });

  final Color landColor;
  final Color borderColor;
  final Color solvedColor;
  final Color solvedBorderColor;
  final double solvedFraction;

  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()
      ..color = landColor
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final solvedPaint = Paint()
      ..color = solvedColor
      ..style = PaintingStyle.fill;
    final solvedBorderPaint = Paint()
      ..color = solvedBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paths = <Path>[
      _continentPath(size, const [
        Offset(0.04, 0.16),
        Offset(0.30, 0.08),
        Offset(0.43, 0.23),
        Offset(0.37, 0.45),
        Offset(0.15, 0.50),
        Offset(0.05, 0.35),
      ]),
      _continentPath(size, const [
        Offset(0.44, 0.18),
        Offset(0.76, 0.12),
        Offset(0.94, 0.28),
        Offset(0.86, 0.54),
        Offset(0.58, 0.58),
        Offset(0.45, 0.40),
      ]),
      _continentPath(size, const [
        Offset(0.42, 0.48),
        Offset(0.55, 0.55),
        Offset(0.51, 0.77),
        Offset(0.44, 0.92),
        Offset(0.35, 0.72),
      ]),
      _continentPath(size, const [
        Offset(0.70, 0.66),
        Offset(0.88, 0.69),
        Offset(0.92, 0.82),
        Offset(0.75, 0.86),
      ]),
    ];

    for (final path in paths) {
      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, borderPaint);
    }

    if (solvedFraction > 0) {
      final highlightIndex = (solvedFraction * paths.length).ceil() - 1;
      final path = paths[highlightIndex.clamp(0, paths.length - 1)];
      canvas.drawPath(path, solvedPaint);
      canvas.drawPath(path, solvedBorderPaint);
    }
  }

  Path _continentPath(Size size, List<Offset> points) {
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(
        points[i].dx * size.width,
        points[i].dy * size.height,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _GeoQuizMapPlaceholderPainter oldDelegate) {
    return oldDelegate.landColor != landColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.solvedColor != solvedColor ||
        oldDelegate.solvedBorderColor != solvedBorderColor ||
        oldDelegate.solvedFraction != solvedFraction;
  }
}
