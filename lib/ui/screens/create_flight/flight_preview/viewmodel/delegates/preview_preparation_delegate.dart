part of '../flight_preview_cubit.dart';

class PreviewPreparationDelegate {
  PreviewPreparationDelegate(
    this._cubit, {
    required ConnectivityChecker connectivityChecker,
    required FlightRouteProvider routeProvider,
    required GetFlightInfoUseCase getFlightInfoUseCase,
    required GetFlightPOIUseCase getFlightPOIUseCase,
  }) : _connectivityChecker = connectivityChecker,
       _routeProvider = routeProvider,
       _getFlightInfoUseCase = getFlightInfoUseCase,
       _getFlightPOIUseCase = getFlightPOIUseCase;

  final FlightPreviewCubit _cubit;
  final ConnectivityChecker _connectivityChecker;
  final FlightRouteProvider _routeProvider;
  final GetFlightInfoUseCase _getFlightInfoUseCase;
  final GetFlightPOIUseCase _getFlightPOIUseCase;

  Future<void> preparePreview() async {
    final departure = _cubit.departure;
    final arrival = _cubit.arrival;

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
          ),
        );
        return;
      }

      final route = _routeProvider.getRoute(
        departure: departure,
        arrival: arrival,
      );
      final routeLength = MapDownloadConfig.resolveRouteLength(
        route.distanceInKm,
      );
      unawaited(
        _cubit._analytics.log(
          SearchRoutePreparedEvent(
            routeLengthKm: route.distanceInKm,
            routeLength: routeLength,
            mapDetail: _cubit.state.selectedMapDetailLevel,
          ),
        ),
      );
      unawaited(
        _cubit._crashlytics.setContext(
          screen: 'create_flight_map_preview',
          routeLengthKm: route.distanceInKm.round(),
          mapDetail: _cubit.state.selectedMapDetailLevel.name,
        ),
      );
      if (_isAntimeridianRoute(route)) {
        unawaited(
          _cubit._analytics.log(
            SearchRouteNotSupportedEvent(
              reason: 'antimeridian',
              routeLengthKm: route.distanceInKm,
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
            isPreviewLoading: false,
            isWikiSuggestionsLoading: false,
            isOverviewLoading: false,
            flightInfo: FlightInfo.empty,
            articleCandidates: const [],
            clearSelectedArticleUrls: true,
            errorMessage: t.createFlight.mapPreview.routeNotSupportedMsg,
          ),
        );
        return;
      }

      _cubit._emitState(
        _cubit.state.copyWith(
          flightRoute: route,
          isPreviewLoading: false,
          hasInternetForMapPreview: true,
          flightInfo: FlightInfo.empty,
          articleCandidates: const [],
          clearSelectedArticleUrls: true,
          isWikiSuggestionsLoading: true,
          isOverviewLoading: true,
        ),
      );

      unawaited(
        prefetchLocalPois(
          route: route,
          mapDetail: _cubit.state.selectedMapDetailLevel,
        ),
      );
      unawaited(_prefetchOverview(route));
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
        ),
      );
    }
  }

  Future<void> prefetchLocalPois({
    required FlightRoute route,
    required MapDetailLevel mapDetail,
  }) async {
    try {
      _cubit._logger.log(
        'Prefetch local route POIs start route=${route.routeCode} mapDetail=${mapDetail.name}',
      );
      final pois = await _getFlightPOIUseCase.call(
        route: route,
        mapDetail: mapDetail,
      );
      final currentRoute = _cubit.state.flightRoute;
      if (currentRoute == null || currentRoute.routeCode != route.routeCode) {
        _cubit._logger.log(
          'Skip applying local POIs due to route mismatch current=${currentRoute?.routeCode} expected=${route.routeCode}',
        );
        return;
      }
      _cubit._emitState(
        _cubit.state.copyWith(
          flightInfo: _cubit.state.flightInfo.copyWith(poi: pois),
        ),
      );
      final sample = pois.take(5).map((e) => '${e.name}/${e.type}').join(', ');
      _cubit._logger.log(
        'Local route POIs loaded=${pois.length}${sample.isEmpty ? '' : ' sample=[$sample]'}',
      );
    } catch (e) {
      _cubit._logger.error('Failed to prefetch local route POIs: $e');
    }
  }

  Future<void> _prefetchOverview(FlightRoute route) async {
    try {
      final info = await _getFlightInfoUseCase.call(
        airportArrival: route.arrival.name,
        airportDeparture: route.departure.name,
        waypoints: route.waypoints,
      );

      final currentRoute = _cubit.state.flightRoute;
      if (currentRoute == null || currentRoute.routeCode != route.routeCode) {
        return;
      }

      final currentInfo = _cubit.state.flightInfo;
      _cubit._emitState(
        _cubit.state.copyWith(
          flightInfo: currentInfo.copyWith(overview: info.overview),
          isOverviewLoading: false,
          isWikiSuggestionsLoading: true,
        ),
      );
    } catch (e) {
      _cubit._logger.error('Failed to prefetch route overview: $e');
      _cubit._emitState(
        _cubit.state.copyWith(
          isOverviewLoading: false,
          isWikiSuggestionsLoading: false,
          errorMessage: t.createFlight.errors.overviewUnavailableContinue,
        ),
      );
      return;
    }

    try {
      final suggestedCandidates = await _getFlightInfoUseCase
          .getWikiArticleCandidates(
            airportArrival: route.arrival.name,
            airportDeparture: route.departure.name,
            waypoints: route.waypoints,
          );
      _cubit._logger.log(
        'Backend wiki candidates received=${suggestedCandidates.length}',
      );
      if (suggestedCandidates.isNotEmpty) {
        final sample = suggestedCandidates.take(3).map((e) => e.url).join(', ');
        _cubit._logger.log('Backend wiki sample=[$sample]');
      }

      final routeAfterWikiCall = _cubit.state.flightRoute;
      if (routeAfterWikiCall == null ||
          routeAfterWikiCall.routeCode != route.routeCode) {
        _cubit._logger.log(
          'Skip applying backend wiki candidates due to route mismatch',
        );
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
      _cubit._logger.log(
        'Applied backend wiki candidates to state: ${suggestedCandidates.length}',
      );
    } catch (e) {
      _cubit._logger.error('Failed to fetch wiki article suggestions: $e');
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
        ? route.waypoints
        : [route.departure.latLon, route.arrival.latLon];
    for (var i = 1; i < points.length; i++) {
      final deltaLon = points[i].longitude - points[i - 1].longitude;
      if (deltaLon.abs() > 180) {
        return true;
      }
    }
    return false;
  }
}
