import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_operational_data.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/flight_schedule.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:flymap/domain/entity/map_detail_level.dart';
import 'package:flymap/domain/entity/route_overview.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/user_flight_prefs.dart';
import 'package:flymap/domain/entity/wiki_article_candidate.dart';
import 'package:flymap/domain/policy/flight_weather_verdict_policy.dart';
import 'package:flymap/domain/policy/poi_interest_ranking_policy.dart';
import 'package:flymap/domain/policy/poi_limits_policy.dart';
import 'package:flymap/domain/policy/route_region_premium_gate_policy.dart';
import 'package:flymap/i18n/app_localization.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/map_download_config.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/user_flight_prefs_repository.dart';
import 'package:flymap/subscription/pro_limits.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/download_map_use_case.dart';
import 'package:flymap/domain/usecase/download_region_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/domain/usecase/get_route_overview_use_case.dart';
import 'package:flymap/domain/usecase/build_flight_route_preview_use_case.dart';
import 'package:flymap/domain/usecase/get_wiki_articles_use_case.dart';

part 'delegates/preview_preparation_delegate.dart';
part 'delegates/map_and_step_navigation_delegate.dart';
part 'delegates/wiki_selection_delegate.dart';
part 'delegates/download_flow_delegate.dart';

class FlightPreviewCubit extends Cubit<FlightPreviewState> {
  FlightPreviewCubit({
    required this.departure,
    required this.arrival,
    this.flightNumber,
    this.fr24Id,
    FlightSchedule? schedule,
    FetchFlightWeatherUseCase? fetchFlightWeatherUseCase,
    bool hasPendingFlightUnlock = false,
    required ConnectivityChecker connectivityChecker,
    required GetRouteOverviewUseCase getRouteOverviewUseCase,
    required BuildFlightRoutePreviewUseCase buildFlightRoutePreviewUseCase,
    required DownloadMapUseCase downloadMapUseCase,
    required DownloadRegionWikiArticlesUseCase
    downloadRegionWikiArticlesUseCase,
    required DownloadWikipediaArticlesUseCase downloadWikipediaArticlesUseCase,
    required GetWikiArticlesUseCase getWikiArticlesUseCase,
    required UserFlightPrefsRepository userFlightPrefsRepository,
    required FlightRepository flightRepository,
    required SubscriptionRepository subscriptionRepository,
    required FlightUnlockRepository flightUnlockRepository,
    required DeleteFlightUseCase deleteFlightUseCase,
    required AppAnalytics analytics,
    required AppCrashlytics crashlytics,
    RouteMapImageStore? routeMapImageStore,
    bool autoPrepare = true,
  }) : _analytics = analytics,
       _crashlytics = crashlytics,
       _subscriptionRepository = subscriptionRepository,
       _fetchFlightWeatherUseCase = fetchFlightWeatherUseCase,
       super(
         FlightPreviewState.initial().copyWith(
           hasPendingFlightUnlock: hasPendingFlightUnlock,
           flightSchedule: schedule,
         ),
       ) {
    _previewPreparationDelegate = PreviewPreparationDelegate(
      this,
      connectivityChecker: connectivityChecker,
      getRouteOverviewUseCase: getRouteOverviewUseCase,
      buildFlightRoutePreviewUseCase: buildFlightRoutePreviewUseCase,
      getWikiArticlesUseCase: getWikiArticlesUseCase,
      userFlightPrefsRepository: userFlightPrefsRepository,
    );
    _navigationDelegate = MapAndStepNavigationDelegate(this);
    _wikiSelectionDelegate = WikiSelectionDelegate(this);
    _downloadFlowDelegate = DownloadFlowDelegate(
      this,
      downloadMapUseCase: downloadMapUseCase,
      downloadRegionWikiArticlesUseCase: downloadRegionWikiArticlesUseCase,
      downloadWikipediaArticlesUseCase: downloadWikipediaArticlesUseCase,
      flightRepository: flightRepository,
      subscriptionRepository: subscriptionRepository,
      flightUnlockRepository: flightUnlockRepository,
      deleteFlightUseCase: deleteFlightUseCase,
      routeMapImageStore: routeMapImageStore,
    );
    if (autoPrepare) {
      unawaited(preparePreview());
    }
  }

  final _logger = Logger('FlightPreviewCubit');
  final AppAnalytics _analytics;
  final AppCrashlytics _crashlytics;
  final SubscriptionRepository _subscriptionRepository;
  final FetchFlightWeatherUseCase? _fetchFlightWeatherUseCase;
  final Airport departure;
  final Airport arrival;
  final String? flightNumber;
  final String? fr24Id;
  late final PreviewPreparationDelegate _previewPreparationDelegate;
  late final MapAndStepNavigationDelegate _navigationDelegate;
  late final WikiSelectionDelegate _wikiSelectionDelegate;
  late final DownloadFlowDelegate _downloadFlowDelegate;

  Future<void> preparePreview() => _previewPreparationDelegate.preparePreview();

  void continueFromWeather() => _navigationDelegate.continueFromWeather();

  /// Fetches the weather picture for the weather step. Failure is
  /// non-blocking: the step shows a retry and Continue stays available.
  Future<void> fetchWeather({bool force = false}) async {
    // Free flights never touch the weather API — the step shows the demo
    // teaser instead; the fetch fires the moment Pro access is unlocked.
    if (!hasEffectiveProAccess) return;
    // Beyond the reliable horizon the step explains itself — calling the
    // API for a two-months-out flight would only produce garbage.
    if (FlightWeatherVerdictPolicy.isBeyondForecastHorizon(
      state.flightSchedule,
      now: DateTime.now(),
    )) {
      return;
    }
    final useCase = _fetchFlightWeatherUseCase;
    final route = state.flightRoute;
    if (useCase == null || route == null) {
      _emitState(state.copyWith(weatherFailed: true));
      return;
    }
    if (state.isWeatherLoading) return;
    if (!force && state.flightWeather != null) return;

    _emitState(state.copyWith(isWeatherLoading: true, weatherFailed: false));
    try {
      final weather = await useCase.call(
        route: route,
        schedule: state.flightSchedule,
      );
      if (isClosed) return;
      _emitState(
        state.copyWith(isWeatherLoading: false, flightWeather: weather),
      );
    } catch (e) {
      _logger.error('Weather fetch failed: $e');
      if (isClosed) return;
      _emitState(state.copyWith(isWeatherLoading: false, weatherFailed: true));
    }
  }

  void continueFromOverview({
    required bool isSkipped,
    required bool isProUser,
  }) {
    unawaited(
      _analytics.log(
        RouteOverviewCompletedEvent(
          isSkipped: isSkipped,
          isProUser: isProUser,
          routeSource:
              state.flightRoute?.source ?? FlightRouteSource.greatCircle,
        ),
      ),
    );
    _navigationDelegate.continueFromOverview();
  }

  void dismissOverviewWarning() {
    _emitState(
      state.copyWith(
        clearOverviewWarningTitle: true,
        clearOverviewWarningMessage: true,
      ),
    );
  }

  void toggleWikiArticleSelection(String url) =>
      _wikiSelectionDelegate.toggleWikiArticleSelection(url);

  void toggleAllWikiArticleSelections() =>
      _wikiSelectionDelegate.toggleAllWikiArticleSelections();

  Future<void> startDownload() => _downloadFlowDelegate.startDownload();

  void cancelDownload() => _downloadFlowDelegate.cancelDownload();

  Future<bool> handleBackAction() => _navigationDelegate.handleBackAction();

  bool get hasEffectiveProAccess =>
      _subscriptionRepository.currentStatus.isPro ||
      state.hasPendingFlightUnlock;

  void _applyPoisForSubscriptionTier(
    List<RoutePoiSummary> allPois, {
    required bool isProUser,
  }) {
    final maxPois = PoiLimitsPolicy.maxPoisForTier(isProUser: isProUser);
    final selected = allPois.take(maxPois).toList(growable: false);
    final proCount = allPois.length < PoiLimitsPolicy.proMaxPois
        ? allPois.length
        : PoiLimitsPolicy.proMaxPois;
    _emitState(
      state.copyWith(
        flightInfo: state.flightInfo.copyWith(poi: selected),
        proPoiCount: proCount,
      ),
    );
  }

  Future<void> refreshPoisForPro() async {
    _applyPoisForSubscriptionTier(state.allRoutePois, isProUser: true);
    _fetchWeatherIfOnWeatherStep();
  }

  /// Upgrading from the weather teaser swaps in the real forecast without
  /// leaving the step.
  void _fetchWeatherIfOnWeatherStep() {
    if (state.step == CreateFlightStep.weather) unawaited(fetchWeather());
  }

  Future<void> syncPoisForCurrentAccessTier() async {
    _applyPoisForSubscriptionTier(
      state.allRoutePois,
      isProUser: hasEffectiveProAccess,
    );
  }

  Future<void> enablePendingFlightUnlock() async {
    _emitState(state.copyWith(hasPendingFlightUnlock: true));
    await syncPoisForCurrentAccessTier();
    _fetchWeatherIfOnWeatherStep();
  }

  Future<void> clearPendingFlightUnlock() async {
    if (!state.hasPendingFlightUnlock) return;
    _emitState(state.copyWith(hasPendingFlightUnlock: false));
    await syncPoisForCurrentAccessTier();
  }

  void _emitState(FlightPreviewState nextState) {
    // Async delegate callbacks may complete after the cubit is disposed.
    if (isClosed) return;
    emit(nextState);
  }

  @override
  Future<void> close() {
    _downloadFlowDelegate.dispose();
    return super.close();
  }
}
