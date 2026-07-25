import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/airport.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/flight_article.dart';
import 'package:flymap/domain/entity/flight_info.dart';
import 'package:flymap/domain/entity/flight_operational_data.dart';
import 'package:flymap/domain/entity/flight_route.dart';
import 'package:flymap/domain/entity/flight_route_source.dart';
import 'package:flymap/domain/entity/map_detail_level.dart';
import 'package:flymap/domain/entity/route_overview.dart';
import 'package:flymap/domain/entity/route_poi_summary.dart';
import 'package:flymap/domain/entity/route_region.dart';
import 'package:flymap/domain/entity/user_flight_prefs.dart';
import 'package:flymap/domain/entity/wiki_article_candidate.dart';
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
    bool autoPrepare = true,
  }) : _analytics = analytics,
       _crashlytics = crashlytics,
       _subscriptionRepository = subscriptionRepository,
       super(
         FlightPreviewState.initial().copyWith(
           hasPendingFlightUnlock: hasPendingFlightUnlock,
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
    );
    if (autoPrepare) {
      unawaited(preparePreview());
    }
  }

  final _logger = Logger('FlightPreviewCubit');
  final AppAnalytics _analytics;
  final AppCrashlytics _crashlytics;
  final SubscriptionRepository _subscriptionRepository;
  final Airport departure;
  final Airport arrival;
  final String? flightNumber;
  final String? fr24Id;
  late final PreviewPreparationDelegate _previewPreparationDelegate;
  late final MapAndStepNavigationDelegate _navigationDelegate;
  late final WikiSelectionDelegate _wikiSelectionDelegate;
  late final DownloadFlowDelegate _downloadFlowDelegate;

  Future<void> preparePreview() => _previewPreparationDelegate.preparePreview();

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
