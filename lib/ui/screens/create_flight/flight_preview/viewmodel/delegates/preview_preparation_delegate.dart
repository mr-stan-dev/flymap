part of '../flight_preview_cubit.dart';

class PreviewPreparationDelegate {
  PreviewPreparationDelegate(
    this._cubit, {
    required ConnectivityChecker connectivityChecker,
    required GetRouteOverviewUseCase getRouteOverviewUseCase,
    required BuildFlightRoutePreviewUseCase buildFlightRoutePreviewUseCase,
    required GetWikiArticlesUseCase getWikiArticlesUseCase,
    required UserFlightPrefsRepository userFlightPrefsRepository,
  }) : _connectivityChecker = connectivityChecker,
       _getRouteOverviewUseCase = getRouteOverviewUseCase,
       _buildFlightRoutePreviewUseCase = buildFlightRoutePreviewUseCase,
       _getWikiArticlesUseCase = getWikiArticlesUseCase,
       _userFlightPrefsRepository = userFlightPrefsRepository;

  final FlightPreviewCubit _cubit;
  final ConnectivityChecker _connectivityChecker;
  final GetRouteOverviewUseCase _getRouteOverviewUseCase;
  final BuildFlightRoutePreviewUseCase _buildFlightRoutePreviewUseCase;
  final GetWikiArticlesUseCase _getWikiArticlesUseCase;
  final UserFlightPrefsRepository _userFlightPrefsRepository;

  Future<void> preparePreview() async {
    final departure = _cubit.departure;
    final arrival = _cubit.arrival;
    final flightNumber = _cubit.flightNumber;
    final fr24Id = _cubit.fr24Id;

    try {
      final hasInternet = await _connectivityChecker.hasInternetConnectivity();
      if (!hasInternet) {
        _cubit._emitState(
          _cubit.state.copyWith(
            isPreviewLoading: false,
            isWikiSuggestionsLoading: false,
            isOverviewLoading: false,
            hasInternetForMapPreview: false,
            clearErrorMessage: true,
            clearOverviewWarningTitle: true,
            clearOverviewWarningMessage: true,
          ),
        );
        return;
      }

      final RouteOverview overview;
      FlightOperationalData? operationalData;
      if (flightNumber != null && flightNumber.trim().isNotEmpty) {
        FlightRoutePreviewResult? result;
        try {
          result = await _buildFlightRoutePreviewUseCase.call(
            flightNumber: flightNumber,
            fr24Id: fr24Id,
            origCode: departure.icaoCode,
            destCode: arrival.icaoCode,
            lang: AppLocalization.currentLanguageCode,
          );
        } on FirebaseFunctionsException catch (e) {
          // FR24 has never recorded this route (brand-new/seasonal leg).
          // The flight is still real — the schedule provider confirmed it —
          // so fall back to the generated route for the known airport pair
          // instead of dead-ending. Same pipeline as approximate flights;
          // only the actual recorded track shape is lost.
          if (e.code != 'not-found') rethrow;
          _cubit._logger.log(
            'no recorded track for $flightNumber — generated-route fallback',
          );
        }
        if (result != null) {
          overview = _getRouteOverviewUseCase.fromPayload(
            payload: result.payload,
            departure: result.departure,
            arrival: result.arrival,
          );
          operationalData = _buildOperationalData(
            overview: overview,
            fallbackFlightNumber: flightNumber,
            departureCode: result.departure.primaryCode,
            arrivalCode: result.arrival.primaryCode,
          );
        } else {
          overview = await _getRouteOverviewUseCase.call(
            departure: departure,
            arrival: arrival,
          );
          operationalData = _buildOperationalData(
            overview: overview,
            fallbackFlightNumber: flightNumber,
            departureCode: departure.icaoCode.trim().isNotEmpty
                ? departure.icaoCode
                : departure.iataCode,
            arrivalCode: arrival.icaoCode.trim().isNotEmpty
                ? arrival.icaoCode
                : arrival.iataCode,
          );
        }
      } else {
        overview = await _getRouteOverviewUseCase.call(
          departure: departure,
          arrival: arrival,
        );
        operationalData = null;
      }
      final route = overview.route;
      final timeline = overview.timeline;
      final routeLength = MapDownloadConfig.resolveRouteLength(
        route.distanceInKm,
      );
      final effectiveMapDetail = _cubit.hasEffectiveProAccess
          ? MapDetailLevel.pro
          : MapDetailLevel.basic;
      unawaited(
        _cubit._analytics.log(
          SearchRoutePreparedEvent(
            routeLengthKm: route.distanceInKm,
            routeLength: routeLength,
            mapDetail: effectiveMapDetail,
            routeSource: route.source,
            creationAttemptId: _cubit.creationAttemptId,
          ),
        ),
      );
      unawaited(
        _cubit._crashlytics.setContext(
          screen: 'create_flight_map_preview',
          routeLengthKm: route.distanceInKm.round(),
          mapDetail: effectiveMapDetail.name,
        ),
      );
      if (_isAntimeridianRoute(route)) {
        _cubit._routeNotSupportedReason = 'antimeridian';
        unawaited(
          _cubit._analytics.log(
            SearchRouteNotSupportedEvent(
              reason: 'antimeridian',
              routeLengthKm: route.distanceInKm,
              routeSource: route.source,
              routeLength: routeLength,
              creationAttemptId: _cubit.creationAttemptId,
            ),
          ),
        );
        unawaited(
          _cubit._crashlytics.setContext(
            screen: 'create_flight_route_not_supported',
          ),
        );
        _cubit._emitState(
          _cubit.state.copyWith(
            step: CreateFlightStep.routeNotSupported,
            flightRoute: route,
            flightOperationalData: operationalData,
            isPreviewLoading: false,
            isWikiSuggestionsLoading: false,
            isOverviewLoading: false,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            errorMessage: t.createFlight.mapPreview.routeNotSupportedMsg,
            clearOverviewWarningTitle: true,
            clearOverviewWarningMessage: true,
          ),
        );
        return;
      }

      if (!route.isHistoricalTrack && routeLength == RouteLength.superLong) {
        _cubit._routeNotSupportedReason = 'approximate_super_long';
        unawaited(
          _cubit._analytics.log(
            SearchRouteNotSupportedEvent(
              reason: 'approximate_super_long',
              routeLengthKm: route.distanceInKm,
              routeSource: route.source,
              routeLength: routeLength,
              recommendedNextAction: 'real_route',
              creationAttemptId: _cubit.creationAttemptId,
            ),
          ),
        );
        _cubit._emitState(
          _cubit.state.copyWith(
            step: CreateFlightStep.routeNotSupported,
            flightRoute: route,
            flightOperationalData: operationalData,
            isPreviewLoading: false,
            isWikiSuggestionsLoading: false,
            isOverviewLoading: false,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            errorMessage: t
                .createFlight
                .overview
                .approximateRouteUltraLongHaulUnsupportedBody,
            clearOverviewWarningTitle: true,
            clearOverviewWarningMessage: true,
          ),
        );
        return;
      }

      final showApproximateRouteWarning =
          !route.isHistoricalTrack &&
          routeLength.minDistanceKm >= RouteLength.long.minDistanceKm;

      final userPrefs = await _loadUserPrefs();
      _cubit._emitState(
        _cubit.state.copyWith(
          flightRoute: route,
          flightOperationalData: operationalData,
          allRoutePois: overview.topPois,
          routeRegions: timeline.regions,
          routeBlockMinutes: timeline.blockMinutes,
          routeCruiseSpeedKmh: timeline.cruiseSpeedKmh,
          isPreviewLoading: false,
          hasInternetForMapPreview: true,
          flightInfo: FlightInfo.empty.copyWith(
            // Interests influence which POIs make the tier cap, so a
            // volcano lover's free 10 actually contains volcanoes.
            poi: PoiInterestRankingPolicy.selectForTier(
              overview.topPois,
              isProUser: _cubit.hasEffectiveProAccess,
              interests: userPrefs.interests,
            ),
            routeRegions: timeline.regions,
            routeMetrics: route.metrics,
          ),
          proPoiCount: overview.topPois.length < PoiLimitsPolicy.proMaxPois
              ? overview.topPois.length
              : PoiLimitsPolicy.proMaxPois,
          articleCandidates: const [],
          clearSelectedArticleUrls: true,
          isWikiSuggestionsLoading: true,
          isOverviewLoading: false,
          overviewWarningTitle: showApproximateRouteWarning
              ? t.createFlight.overview.approximateRouteLongHaulWarningTitle
              : null,
          clearOverviewWarningTitle: !showApproximateRouteWarning,
          overviewWarningMessage: showApproximateRouteWarning
              ? t.createFlight.overview.approximateRouteLongHaulWarningBody
              : null,
          clearOverviewWarningMessage: !showApproximateRouteWarning,
        ),
      );

      // For an already-entitled flight, overlap the weather request with the
      // time spent viewing the route overview. The weather step reuses the
      // same state and fetchWeather deduplicates if it is still in flight.
      _cubit._prefetchWeatherIfEligible();
      unawaited(_prefetchWiki(route, userPrefs: userPrefs));
    } catch (e, stackTrace) {
      _cubit._logger.error('Failed to prepare map preview: $e');
      unawaited(
        _cubit._crashlytics.recordError(
          e,
          stackTrace,
          reason: 'prepare_preview_failed',
        ),
      );
      _cubit._emitState(
        _cubit.state.copyWith(
          isPreviewLoading: false,
          isWikiSuggestionsLoading: false,
          isOverviewLoading: false,
          errorMessage: t.createFlight.errors.failedBuildPreview,
          clearOverviewWarningTitle: true,
          clearOverviewWarningMessage: true,
        ),
      );
    }
  }

  Future<void> _prefetchWiki(
    FlightRoute route, {
    UserFlightPrefs? userPrefs,
  }) async {
    final prefs = userPrefs ?? await _loadUserPrefs();

    try {
      final suggestedCandidates = await _getWikiArticlesUseCase.call(
        airportArrival: route.arrival.name,
        airportDeparture: route.departure.name,
        waypoints: route.waypointLatLngs,
        interests: prefs.interests,
      );

      final routeAfterWikiCall = _cubit.state.flightRoute;
      if (routeAfterWikiCall == null ||
          routeAfterWikiCall.routeCode != route.routeCode) {
        return;
      }

      _cubit._emitState(
        _cubit.state.copyWith(
          articleCandidates: suggestedCandidates,
          selectedArticleUrls: _retainSelectedArticleUrls(
            selectedUrls: _cubit.state.selectedArticleUrls,
            candidates: suggestedCandidates,
          ),
          isWikiSuggestionsLoading: false,
        ),
      );
    } catch (e) {
      _cubit._logger.error('Failed to prefetch wiki articles: $e');
      _cubit._emitState(_cubit.state.copyWith(isWikiSuggestionsLoading: false));
    }
  }

  List<String> _retainSelectedArticleUrls({
    required List<String> selectedUrls,
    required List<WikiArticleCandidate> candidates,
  }) {
    final candidateUrls = candidates.map((candidate) => candidate.url).toSet();
    return selectedUrls.where(candidateUrls.contains).toList();
  }

  bool _isAntimeridianRoute(FlightRoute route) {
    final points = route.waypoints.length >= 2
        ? route.waypointLatLngs
        : [route.departure.latLon, route.arrival.latLon];
    for (var i = 1; i < points.length; i++) {
      final deltaLon = points[i].longitude - points[i - 1].longitude;
      if (deltaLon.abs() > 180) {
        return true;
      }
    }
    return false;
  }

  Future<UserFlightPrefs> _loadUserPrefs() async {
    try {
      return await _userFlightPrefsRepository.getPrefs();
    } catch (e) {
      _cubit._logger.error('Failed to load user flight prefs: $e');
      return const UserFlightPrefs.empty();
    }
  }

  FlightOperationalData _buildOperationalData({
    required RouteOverview overview,
    required String fallbackFlightNumber,
    required String departureCode,
    required String arrivalCode,
  }) {
    final summary = overview.flightInfo;
    return FlightOperationalData(
      flightNumber: _requireNonEmpty(
        _normalizeNonEmpty(summary?.flightNumber) ??
            _normalizeNonEmpty(fallbackFlightNumber),
        field: 'flightNumber',
      ),
      airlineCode:
          _normalizeNonEmpty(summary?.airlineCode) ??
          _normalizeNonEmpty(_cubit.airlineCodeHint),
      airlineName:
          _normalizeNonEmpty(summary?.airlineName) ??
          _normalizeNonEmpty(_cubit.airlineNameHint),
      originCode: _requireNonEmpty(
        _normalizeNonEmpty(summary?.origIcao) ??
            _normalizeNonEmpty(departureCode),
        field: 'originCode',
      ),
      destinationCode: _requireNonEmpty(
        _normalizeNonEmpty(summary?.destIcao) ??
            _normalizeNonEmpty(arrivalCode),
        field: 'destinationCode',
      ),
      observedAt: DateTime.now(),
    );
  }

  String? _normalizeNonEmpty(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }

  String _requireNonEmpty(String? value, {required String field}) {
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required operational field: $field');
    }
    return value;
  }
}
