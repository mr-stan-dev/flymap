part of '../flight_preview_cubit.dart';

class DownloadFlowDelegate {
  static const _accessModeBasic = 'basic';
  static const _accessModeSubscription = 'subscription';
  static const _accessModeSingleFlightUnlock = 'single_flight_unlock';

  DownloadFlowDelegate(
    this._cubit, {
    required DownloadMapUseCase downloadMapUseCase,
    required DownloadRegionWikiArticlesUseCase
    downloadRegionWikiArticlesUseCase,
    required DownloadWikipediaArticlesUseCase downloadWikipediaArticlesUseCase,
    required FlightRepository flightRepository,
    required SubscriptionRepository subscriptionRepository,
    required FlightUnlockRepository flightUnlockRepository,
    required DeleteFlightUseCase deleteFlightUseCase,
    RouteMapImageStore? routeMapImageStore,
  }) : _downloadMapUseCase = downloadMapUseCase,
       _downloadRegionWikiArticlesUseCase = downloadRegionWikiArticlesUseCase,
       _downloadWikipediaArticlesUseCase = downloadWikipediaArticlesUseCase,
       _flightRepository = flightRepository,
       _subscriptionRepository = subscriptionRepository,
       _flightUnlockRepository = flightUnlockRepository,
       _deleteFlightUseCase = deleteFlightUseCase,
       _routeMapImageStore = routeMapImageStore;

  final FlightPreviewCubit _cubit;
  final DownloadMapUseCase _downloadMapUseCase;
  final DownloadRegionWikiArticlesUseCase _downloadRegionWikiArticlesUseCase;
  final DownloadWikipediaArticlesUseCase _downloadWikipediaArticlesUseCase;
  final FlightRepository _flightRepository;
  final RouteMapImageStore? _routeMapImageStore;

  /// Best-effort, fire-and-forget: fetch the home card's map thumbnail and
  /// the weather card's satellite base while the flight is being created
  /// (network is guaranteed here). Only flights created after each feature
  /// get their cached image — there is no backfill.
  void _prefetchCardMapImage({
    required String flightId,
    required FlightRoute route,
  }) {
    final store = _routeMapImageStore;
    if (store == null) return;
    final waypoints = route.waypointLatLngs;
    final points = waypoints.length >= 2
        ? waypoints
        : [route.departure.latLon, route.arrival.latLon];
    unawaited(
      store.getOrFetchCardImage(flightId: flightId, routePoints: points),
    );
    // The weather screen is often opened in airplane mode; without this its
    // map base is blank offline (only the clouds render from stored data).
    unawaited(
      store.getOrFetchWeatherImage(flightId: flightId, routePoints: points),
    );
  }

  final SubscriptionRepository _subscriptionRepository;
  final FlightUnlockRepository _flightUnlockRepository;
  final DeleteFlightUseCase _deleteFlightUseCase;

  StreamSubscription? _downloadSubscription;
  bool _downloadCancelled = false;
  String? _savedFlightIdDuringDownload;
  String? _activeArticleBundleId;
  bool _usedPendingFlightUnlockForCurrentDownload = false;
  bool _didConsumePendingFlightUnlock = false;

  bool get currentSubscriptionIsPro =>
      _subscriptionRepository.currentStatus.isPro;

  int get _freeWikiArticlesSelectionLimit =>
      ProLimits.freeWikiArticlesSelectionLimit;

  /// Flight-scoped: article media is owned by one flight, so cancel/failure
  /// cleanup of this bundle can never touch another flight's images. Legacy
  /// route-scoped bundles remain protected by FlightAssetsDeleter.
  String _articleBundleId(FlightRoute route, String flightId) =>
      '${route.routeCode}_${route.departure.displayCode}_${route.arrival.displayCode}_$flightId';

  String _articlesProgressMessage({
    required int completed,
    required int total,
    required int failed,
  }) {
    if (failed > 0) {
      return t.createFlight.downloading.articlesProgressWithFailed(
        completed: completed,
        total: total,
        failed: failed,
      );
    }
    return t.createFlight.downloading.articlesProgress(
      completed: completed,
      total: total,
    );
  }

  List<RouteRegion> _downloadableRegions({required bool isProUser}) {
    final routeRegions = _cubit.state.flightInfo.routeRegions;
    if (isProUser || routeRegions.isEmpty) {
      return routeRegions;
    }
    final orderedByDistance = RouteRegionPremiumGatePolicy.orderByDistance(
      routeRegions,
    );
    final gateDecision = RouteRegionPremiumGatePolicy.evaluate(
      orderedRegions: orderedByDistance,
      isProUser: false,
    );
    if (!gateDecision.isGated) {
      return routeRegions;
    }
    final freeRegionIds = gateDecision.freeRegionIds;
    return routeRegions
        .where((region) => freeRegionIds.contains(region.qid))
        .toList(growable: false);
  }

  List<RouteRegion> _mergeResolvedRegions({
    required List<RouteRegion> allRegions,
    required List<RouteRegion> resolvedSubset,
  }) {
    if (resolvedSubset.isEmpty) {
      return allRegions;
    }
    final resolvedByQid = <String, RouteRegion>{
      for (final region in resolvedSubset) region.qid: region,
    };
    return allRegions
        .map((region) => resolvedByQid[region.qid] ?? region)
        .toList(growable: false);
  }

  List<FlightArticle> _assignRegionQidsToArticles({
    required List<FlightArticle> articles,
    required List<RouteRegion> regions,
  }) {
    if (articles.isEmpty || regions.isEmpty) return articles;
    final regionQidByWikiUrl = <String, String>{};
    for (final region in regions) {
      final wikiUrl = _normalizeWikiUrl(region.wikipediaUrl);
      if (wikiUrl == null || regionQidByWikiUrl.containsKey(wikiUrl)) continue;
      regionQidByWikiUrl[wikiUrl] = region.qid;
    }
    if (regionQidByWikiUrl.isEmpty) return articles;
    return articles
        .map((article) {
          final normalizedSourceUrl = _normalizeWikiUrl(article.sourceUrl);
          final regionQid = normalizedSourceUrl == null
              ? null
              : regionQidByWikiUrl[normalizedSourceUrl];
          if (regionQid == null) return article;
          return FlightArticle(
            sourceUrl: article.sourceUrl,
            title: article.title,
            summary: article.summary,
            contentPlainText: article.contentPlainText,
            contentHtml: article.contentHtml,
            languageCode: article.languageCode,
            leadImageRelativePath: article.leadImageRelativePath,
            inlineImageRelativePaths: article.inlineImageRelativePaths,
            attributionText: article.attributionText,
            licenseText: article.licenseText,
            downloadedAt: article.downloadedAt,
            sizeBytes: article.sizeBytes,
            qid: regionQid,
          );
        })
        .toList(growable: false);
  }

  String? _normalizeWikiUrl(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = Uri.tryParse(value);
    if (parsed == null) return value.toLowerCase();
    return '${parsed.host.toLowerCase()}${parsed.path.toLowerCase()}';
  }

  String _accessModeForCurrentDownload() {
    if (currentSubscriptionIsPro) return _accessModeSubscription;
    if (_cubit.state.hasPendingFlightUnlock) {
      return _accessModeSingleFlightUnlock;
    }
    return _accessModeBasic;
  }

  Future<void> startDownload() async {
    if (_cubit.state.isDownloading) return;
    final route = _cubit.state.flightRoute;
    if (route == null) return;
    final isPro = _cubit.hasEffectiveProAccess;
    final accessMode = _accessModeForCurrentDownload();
    _usedPendingFlightUnlockForCurrentDownload =
        _cubit.state.hasPendingFlightUnlock && !currentSubscriptionIsPro;
    _didConsumePendingFlightUnlock = false;

    // Defensive sync: ensure Pro downloads always use Pro POI set,
    // even if upgrade happened moments before tapping Download.
    if (isPro) {
      await _cubit.refreshPoisForPro();
    }

    _downloadCancelled = false;
    _savedFlightIdDuringDownload = null;
    _activeArticleBundleId = null;
    await _downloadSubscription?.cancel();

    final selectedUrls =
        (isPro
                ? _cubit.state.selectedArticleUrls
                : _cubit.state.selectedArticleUrls.take(
                    _freeWikiArticlesSelectionLimit,
                  ))
            .toList();
    if (!isPro &&
        selectedUrls.length != _cubit.state.selectedArticleUrls.length) {
      _cubit._emitState(
        _cubit.state.copyWith(selectedArticleUrls: selectedUrls),
      );
    }
    final regionsToDownload = _downloadableRegions(isProUser: isPro);
    final regionsToDownloadCount = _downloadRegionWikiArticlesUseCase
        .downloadTargetCount(regionsToDownload);
    final flightId = DownloadMapUseCase.newFlightId();
    _prefetchCardMapImage(flightId: flightId, route: route);
    final articleBundleId = _articleBundleId(route, flightId);
    _activeArticleBundleId = articleBundleId;
    final initialHasArticlePhase = selectedUrls.isNotEmpty;
    final initialSections = DownloadSectionsState(
      map: DownloadSectionState.initial().copyWith(
        status: DownloadSectionStatus.active,
        message: t.createFlight.downloading.preparingMap,
      ),
      poi: regionsToDownloadCount <= 0
          ? DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.skipped,
            )
          : DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.pending,
              completed: 0,
              total: regionsToDownloadCount,
              failed: 0,
              message: _articlesProgressMessage(
                completed: 0,
                total: regionsToDownloadCount,
                failed: 0,
              ),
            ),
      articles: !initialHasArticlePhase
          ? DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.skipped,
            )
          : DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.pending,
              total: selectedUrls.length,
            ),
    );
    final hasArticlePhase = initialHasArticlePhase;
    var enrichedInfo = _cubit.state.flightInfo.copyWith(articles: const []);
    final mapDetailLevel = isPro ? MapDetailLevel.pro : MapDetailLevel.basic;
    final effectiveMaxZoom = MapDownloadConfig.resolveMaxZoom(
      distanceKm: route.distanceInKm,
      detailLevel: mapDetailLevel,
    );
    final routeLengthKm = route.distanceInKm;

    _cubit._emitState(
      _cubit.state.copyWith(
        step: CreateFlightStep.wikipediaArticles,
        downloadSections: initialSections,
        isDownloading: true,
        downloadProgress: 0.0,
        downloadedBytes: 0,
        downloadStage: DownloadStage.initializing,
        poiDownloadCompleted: 0,
        poiDownloadTotal: 0,
        poiDownloadFailed: 0,
        articleDownloadCompleted: 0,
        articleDownloadTotal: selectedUrls.length,
        articleDownloadFailed: 0,
        clearDownloadTileCount: true,
        clearDownloadWorkerCount: true,
        downloadDone: false,
        clearSavedFlightId: true,
        clearUsedSingleFlightUnlock: true,
        clearDownloadErrorMessage: true,
        clearErrorMessage: true,
      ),
    );
    unawaited(
      _cubit._analytics.log(
        DownloadStartedEvent(
          routeLengthKm: routeLengthKm,
          mapDetail: mapDetailLevel,
          articlesSelectedCount: selectedUrls.length,
          isProUser: isPro,
          accessMode: accessMode,
          routeSource: route.source,
        ),
      ),
    );
    unawaited(
      _cubit._crashlytics.setContext(
        screen: 'create_flight_download',
        routeLengthKm: routeLengthKm.round(),
        mapDetail: mapDetailLevel.name,
        articlesSelectedCount: selectedUrls.length,
        downloadStage: 'initializing',
      ),
    );

    final mapPhase = await _runMapDownloadPhase(
      flightId: flightId,
      route: route,
      infoForSave: enrichedInfo,
      flightOperationalData: _cubit.state.flightOperationalData,
      flightSchedule: _cubit.state.flightSchedule,
      flightAccessTier: isPro ? Flight.accessTierPro : Flight.accessTierBasic,
      effectiveMaxZoom: effectiveMaxZoom,
      routeLengthKm: routeLengthKm,
    );
    if (!mapPhase.success || _downloadCancelled || _cubit.isClosed) {
      return;
    }

    if (_usedPendingFlightUnlockForCurrentDownload) {
      await _flightUnlockRepository.consumeUnlock();
      _didConsumePendingFlightUnlock = true;
    }

    _savedFlightIdDuringDownload = flightId;
    var regionHadIssues = false;
    var articleHadIssues = false;
    var regionDownloadedArticles = <FlightArticle>[];

    if (regionsToDownloadCount > 0) {
      _cubit._emitState(
        _cubit.state.copyWith(
          isDownloading: true,
          downloadStage: DownloadStage.downloadingPoi,
          downloadSections: _cubit.state.downloadSections.copyWith(
            poi: _cubit.state.downloadSections.poi.copyWith(
              status: DownloadSectionStatus.active,
              total: regionsToDownloadCount,
              completed: 0,
              failed: 0,
              message: _articlesProgressMessage(
                completed: 0,
                total: regionsToDownloadCount,
                failed: 0,
              ),
            ),
          ),
        ),
      );
      var regionMetadataFailed = 0;
      var regionArticleCompleted = 0;
      var regionArticleFailed = 0;
      var regionArticleTotal = 0;
      try {
        final regionResult = await _downloadRegionWikiArticlesUseCase.call(
          regions: regionsToDownload,
          preferredLanguageCode: AppLocalization.currentLanguageCode,
          onProgress: (progress) {
            if (_downloadCancelled || _cubit.isClosed) return;
            _cubit._emitState(
              _cubit.state.copyWith(
                downloadSections: _cubit.state.downloadSections.copyWith(
                  poi: _cubit.state.downloadSections.poi.copyWith(
                    status: DownloadSectionStatus.active,
                    completed: progress.completed,
                    total: progress.total,
                    failed: progress.failed,
                    message: _articlesProgressMessage(
                      completed: progress.completed,
                      total: progress.total,
                      failed: progress.failed,
                    ),
                  ),
                ),
              ),
            );
          },
        );
        if (_downloadCancelled || _cubit.isClosed || regionResult.cancelled) {
          return;
        }
        regionMetadataFailed = regionResult.failedCount;
        enrichedInfo = enrichedInfo.copyWith(
          routeRegions: _mergeResolvedRegions(
            allRegions: enrichedInfo.routeRegions,
            resolvedSubset: regionResult.regions,
          ),
        );

        final regionArticleUrls = regionResult.articleUrls;
        regionArticleTotal = regionArticleUrls.length;
        if (regionArticleTotal > 0) {
          _cubit._emitState(
            _cubit.state.copyWith(
              isDownloading: true,
              downloadStage: DownloadStage.downloadingPoi,
              poiDownloadCompleted: 0,
              poiDownloadTotal: regionArticleTotal,
              poiDownloadFailed: 0,
              downloadSections: _cubit.state.downloadSections.copyWith(
                poi: _cubit.state.downloadSections.poi.copyWith(
                  status: DownloadSectionStatus.active,
                  completed: 0,
                  total: regionArticleTotal,
                  failed: 0,
                  message: _articlesProgressMessage(
                    completed: 0,
                    total: regionArticleTotal,
                    failed: 0,
                  ),
                ),
              ),
            ),
          );

          final regionArticlesResult = await _downloadWikipediaArticlesUseCase
              .call(
                bundleId: articleBundleId,
                articleUrls: regionArticleUrls,
                onProgress: (progress) {
                  if (_downloadCancelled || _cubit.isClosed) return;
                  regionArticleCompleted = progress.completed;
                  regionArticleFailed = progress.failed;
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadStage: DownloadStage.downloadingPoi,
                      poiDownloadCompleted: regionArticleCompleted,
                      poiDownloadTotal: regionArticleTotal,
                      poiDownloadFailed: regionArticleFailed,
                      downloadProgress: 0.0,
                      downloadDone: false,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        poi: _cubit.state.downloadSections.poi.copyWith(
                          status: DownloadSectionStatus.active,
                          completed: regionArticleCompleted,
                          total: regionArticleTotal,
                          failed: regionArticleFailed,
                          message: _articlesProgressMessage(
                            completed: regionArticleCompleted,
                            total: regionArticleTotal,
                            failed: regionArticleFailed,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
          if (_downloadCancelled ||
              _cubit.isClosed ||
              regionArticlesResult.cancelled) {
            return;
          }
          regionDownloadedArticles = _assignRegionQidsToArticles(
            articles: regionArticlesResult.articles,
            regions: enrichedInfo.routeRegions,
          );
          regionArticleCompleted = regionArticleTotal;
          regionArticleFailed = regionArticlesResult.failedCount;
          enrichedInfo = enrichedInfo.copyWith(
            articles: regionDownloadedArticles,
          );
        }

        final persisted = await _flightRepository.updateFlightInfo(
          flightId: flightId,
          info: enrichedInfo,
        );
        if (regionArticleTotal <= 0) {
          _cubit._emitState(
            _cubit.state.copyWith(
              isDownloading: true,
              downloadStage: hasArticlePhase
                  ? DownloadStage.downloadingArticles
                  : DownloadStage.completed,
              poiDownloadCompleted: 0,
              poiDownloadTotal: 0,
              poiDownloadFailed: 0,
              downloadProgress: 0.0,
              downloadSections: _cubit.state.downloadSections.copyWith(
                poi: _cubit.state.downloadSections.poi.copyWith(
                  status: DownloadSectionStatus.skipped,
                  completed: 0,
                  total: 0,
                  failed: 0,
                  message: t.createFlight.downloading.noArticlesSelected,
                ),
              ),
            ),
          );
        } else {
          final regionTotalForSection = regionArticleTotal;
          final regionFailedForSection =
              regionArticleFailed + regionMetadataFailed + (!persisted ? 1 : 0);
          final regionCompletedForSection = regionTotalForSection;
          final clampedRegionFailed = regionFailedForSection
              .clamp(0, regionTotalForSection)
              .toInt();

          regionHadIssues = clampedRegionFailed > 0;
          _cubit._emitState(
            _cubit.state.copyWith(
              isDownloading: true,
              downloadStage: hasArticlePhase
                  ? DownloadStage.downloadingArticles
                  : DownloadStage.completed,
              poiDownloadCompleted: regionCompletedForSection,
              poiDownloadTotal: regionTotalForSection,
              poiDownloadFailed: clampedRegionFailed,
              downloadProgress: 0.0,
              downloadSections: _cubit.state.downloadSections.copyWith(
                poi: _cubit.state.downloadSections.poi.copyWith(
                  status: regionHadIssues
                      ? DownloadSectionStatus.completedWithIssues
                      : DownloadSectionStatus.completed,
                  completed: regionCompletedForSection,
                  total: regionTotalForSection,
                  failed: clampedRegionFailed,
                  message: regionHadIssues
                      ? t.createFlight.downloading.completedWithIssues
                      : t.createFlight.downloading.completed,
                ),
              ),
            ),
          );
        }
      } catch (e, stackTrace) {
        _cubit._logger.error(
          'Region article download failed; continuing with map/article download: $e',
        );
        unawaited(
          _cubit._crashlytics.recordError(
            e,
            stackTrace,
            reason: 'region_article_download_failed',
          ),
        );
        if (_downloadCancelled || _cubit.isClosed) return;
        regionHadIssues = true;
        _cubit._emitState(
          _cubit.state.copyWith(
            isDownloading: true,
            downloadStage: hasArticlePhase
                ? DownloadStage.downloadingArticles
                : DownloadStage.completed,
            poiDownloadCompleted: regionsToDownloadCount,
            poiDownloadTotal: regionsToDownloadCount,
            poiDownloadFailed: regionsToDownloadCount,
            downloadProgress: 0.0,
            downloadSections: _cubit.state.downloadSections.copyWith(
              poi: _cubit.state.downloadSections.poi.copyWith(
                status: DownloadSectionStatus.failed,
                completed: regionsToDownloadCount,
                total: regionsToDownloadCount,
                failed: regionsToDownloadCount,
                message: t.createFlight.downloading.failed,
              ),
            ),
          ),
        );
      }
    }

    if (_downloadCancelled || _cubit.isClosed) return;

    final effectiveArticleUrls = selectedUrls;
    var downloadedArticles = <FlightArticle>[...regionDownloadedArticles];
    if (hasArticlePhase) {
      _cubit._emitState(
        _cubit.state.copyWith(
          isDownloading: true,
          downloadStage: DownloadStage.downloadingArticles,
          articleDownloadTotal: effectiveArticleUrls.length,
          downloadSections: _cubit.state.downloadSections.copyWith(
            articles: _cubit.state.downloadSections.articles.copyWith(
              status: DownloadSectionStatus.active,
              total: effectiveArticleUrls.length,
              message: t.createFlight.downloading.preparingArticles,
            ),
          ),
        ),
      );
      try {
        final result = await _downloadWikipediaArticlesUseCase.call(
          bundleId: articleBundleId,
          articleUrls: effectiveArticleUrls,
          onProgress: (progress) {
            if (_downloadCancelled || _cubit.isClosed) return;
            _cubit._emitState(
              _cubit.state.copyWith(
                isDownloading: true,
                downloadStage: DownloadStage.downloadingArticles,
                articleDownloadCompleted: progress.completed,
                articleDownloadTotal: progress.total,
                articleDownloadFailed: progress.failed,
                downloadProgress: 0.0,
                downloadDone: false,
                downloadSections: _cubit.state.downloadSections.copyWith(
                  articles: _cubit.state.downloadSections.articles.copyWith(
                    status: DownloadSectionStatus.active,
                    completed: progress.completed,
                    total: progress.total,
                    failed: progress.failed,
                    message: progress.failed > 0
                        ? t.createFlight.downloading.articlesProgressWithFailed(
                            completed: progress.completed,
                            total: progress.total,
                            failed: progress.failed,
                          )
                        : t.createFlight.downloading.articlesProgress(
                            completed: progress.completed,
                            total: progress.total,
                          ),
                  ),
                ),
              ),
            );
          },
        );

        if (_downloadCancelled || _cubit.isClosed || result.cancelled) {
          return;
        }

        downloadedArticles = [...regionDownloadedArticles, ...result.articles];
        enrichedInfo = enrichedInfo.copyWith(articles: downloadedArticles);
        final persisted = await _flightRepository.updateFlightInfo(
          flightId: flightId,
          info: enrichedInfo,
        );
        articleHadIssues = result.failedCount > 0 || !persisted;
        _cubit._emitState(
          _cubit.state.copyWith(
            isDownloading: true,
            downloadStage: DownloadStage.completed,
            poiDownloadCompleted: _cubit.state.poiDownloadCompleted,
            poiDownloadTotal: _cubit.state.poiDownloadTotal,
            poiDownloadFailed: _cubit.state.poiDownloadFailed,
            articleDownloadCompleted: effectiveArticleUrls.length,
            articleDownloadTotal: effectiveArticleUrls.length,
            articleDownloadFailed: result.failedCount,
            downloadProgress: 0.0,
            downloadSections: _cubit.state.downloadSections.copyWith(
              articles: _cubit.state.downloadSections.articles.copyWith(
                status: articleHadIssues
                    ? DownloadSectionStatus.completedWithIssues
                    : DownloadSectionStatus.completed,
                completed: effectiveArticleUrls.length,
                total: effectiveArticleUrls.length,
                failed: result.failedCount + (!persisted ? 1 : 0),
                message: articleHadIssues
                    ? t.createFlight.downloading.completedWithIssues
                    : t.createFlight.downloading.completed,
              ),
            ),
          ),
        );
      } catch (e) {
        _cubit._logger.error(
          'Article download failed; continuing with map-only download: $e',
        );
        unawaited(
          _cubit._crashlytics.recordError(
            e,
            StackTrace.current,
            reason: 'article_download_failed',
          ),
        );
        if (_downloadCancelled || _cubit.isClosed) return;
        articleHadIssues = true;
        _cubit._emitState(
          _cubit.state.copyWith(
            isDownloading: true,
            downloadStage: DownloadStage.completed,
            poiDownloadCompleted: _cubit.state.poiDownloadCompleted,
            poiDownloadTotal: _cubit.state.poiDownloadTotal,
            poiDownloadFailed: _cubit.state.poiDownloadFailed,
            articleDownloadCompleted: effectiveArticleUrls.length,
            articleDownloadTotal: effectiveArticleUrls.length,
            articleDownloadFailed: effectiveArticleUrls.length,
            downloadProgress: 0.0,
            errorMessage: t.createFlight.errors.someArticlesFailed,
            downloadSections: _cubit.state.downloadSections.copyWith(
              articles: _cubit.state.downloadSections.articles.copyWith(
                status: DownloadSectionStatus.failed,
                completed: effectiveArticleUrls.length,
                total: effectiveArticleUrls.length,
                failed: effectiveArticleUrls.length,
                message: t.createFlight.downloading.failed,
              ),
            ),
          ),
        );
      }
    }

    if (_downloadCancelled || _cubit.isClosed) return;
    unawaited(
      _cubit._analytics.log(
        DownloadCompletedEvent(
          routeLengthKm: routeLengthKm,
          articlesDownloadedCount: downloadedArticles.length,
          mapSizeBytes: mapPhase.fileSize,
          accessMode: accessMode,
          routeSource: route.source,
        ),
      ),
    );
    unawaited(_cubit._crashlytics.setContext(downloadStage: 'completed'));
    _cubit._emitState(
      _cubit.state.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        downloadedBytes: mapPhase.fileSize,
        downloadStage: DownloadStage.completed,
        downloadDone: true,
        savedFlightId: flightId,
        usedSingleFlightUnlock: _usedPendingFlightUnlockForCurrentDownload,
        clearDownloadErrorMessage: true,
        hasPendingFlightUnlock: false,
      ),
    );
  }

  void cancelDownload() {
    if (!_cubit.state.isDownloading) return;
    _downloadCancelled = true;
    final rollbackFlightId = _savedFlightIdDuringDownload;
    final bundleId = _activeArticleBundleId;
    _downloadRegionWikiArticlesUseCase.cancel();
    _downloadWikipediaArticlesUseCase.cancel();
    _downloadMapUseCase.cancel();
    unawaited(_downloadSubscription?.cancel());
    _cubit._emitState(
      _cubit.state.copyWith(
        downloadSections: const DownloadSectionsState.initial(),
        isDownloading: false,
        downloadProgress: 0.0,
        downloadStage: DownloadStage.idle,
        poiDownloadCompleted: 0,
        poiDownloadTotal: 0,
        poiDownloadFailed: 0,
        articleDownloadCompleted: 0,
        articleDownloadTotal: 0,
        articleDownloadFailed: 0,
        clearDownloadTileCount: true,
        clearDownloadWorkerCount: true,
        clearErrorMessage: true,
        clearDownloadErrorMessage: true,
        clearSavedFlightId: true,
        clearUsedSingleFlightUnlock: true,
      ),
    );
    _savedFlightIdDuringDownload = null;
    _activeArticleBundleId = null;
    if (rollbackFlightId != null) {
      unawaited(
        _rollbackSavedFlightAfterCancel(
          flightId: rollbackFlightId,
          bundleId: bundleId,
        ),
      );
    } else if (bundleId != null) {
      unawaited(_downloadWikipediaArticlesUseCase.cleanupBundleMedia(bundleId));
    }
  }

  void dispose() {
    _downloadCancelled = true;
    _savedFlightIdDuringDownload = null;
    _activeArticleBundleId = null;
    _usedPendingFlightUnlockForCurrentDownload = false;
    _didConsumePendingFlightUnlock = false;
    _downloadRegionWikiArticlesUseCase.cancel();
    _downloadWikipediaArticlesUseCase.cancel();
    _downloadMapUseCase.cancel();
    unawaited(_downloadSubscription?.cancel());
  }

  Future<_MapDownloadPhaseResult> _runMapDownloadPhase({
    required String flightId,
    required FlightRoute route,
    required FlightInfo infoForSave,
    FlightOperationalData? flightOperationalData,
    FlightSchedule? flightSchedule,
    required String flightAccessTier,
    required int effectiveMaxZoom,
    required double routeLengthKm,
  }) async {
    final completer = Completer<_MapDownloadPhaseResult>();
    try {
      _downloadSubscription = _downloadMapUseCase
          .call(
            flightId: flightId,
            flightRoute: route,
            flightInfo: infoForSave,
            flightOperationalData: flightOperationalData,
            flightSchedule: flightSchedule,
            flightAccessTier: flightAccessTier,
            maxZoom: effectiveMaxZoom,
          )
          .listen(
            (event) {
              if (_downloadCancelled || _cubit.isClosed) {
                if (!completer.isCompleted) {
                  completer.complete(
                    _MapDownloadPhaseResult(
                      success: false,
                      fileSize: _cubit.state.downloadedBytes,
                    ),
                  );
                }
                return;
              }
              switch (event) {
                case DownloadMapProgress():
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadProgress: event.progress.clamp(0.0, 1.0),
                      downloadedBytes: event.downloadedBytes,
                      downloadStage: DownloadStage.downloading,
                      downloadDone: false,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.active,
                          progress: event.progress.clamp(0.0, 1.0),
                          downloadedBytes: event.downloadedBytes,
                          message: t.createFlight.downloading.downloaded(
                            size: _formatDownloadedMb(event.downloadedBytes),
                          ),
                        ),
                      ),
                    ),
                  );
                  break;
                case DownloadMapDone():
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadProgress: 1.0,
                      downloadedBytes: event.fileSize,
                      downloadStage: DownloadStage.completed,
                      downloadDone: false,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.completed,
                          progress: 1.0,
                          downloadedBytes: event.fileSize,
                          message: t.createFlight.downloading.completed,
                        ),
                      ),
                    ),
                  );
                  if (!completer.isCompleted) {
                    completer.complete(
                      _MapDownloadPhaseResult(
                        success: true,
                        fileSize: event.fileSize,
                      ),
                    );
                  }
                  break;
                case DownloadMapError():
                  final failureReason = _mapDownloadFailureReason(
                    event.errorMsg,
                  );
                  final failureStage = _mapDownloadFailureStage(event.errorMsg);
                  unawaited(
                    _cubit._analytics.log(
                      DownloadFailedEvent(
                        stage: 'map_download',
                        errorType: failureReason,
                        errorMessage: event.errorMsg,
                        routeLengthKm: routeLengthKm,
                        routeSource: route.source,
                      ),
                    ),
                  );
                  unawaited(
                    _cubit._crashlytics.setContext(
                      downloadStage:
                          '$failureStage:${_contextErrorSnippet(event.errorMsg)}',
                    ),
                  );
                  unawaited(
                    _cubit._crashlytics.recordError(
                      Exception(
                        '[map-download:$failureReason] ${event.errorMsg}',
                      ),
                      StackTrace.current,
                      reason: failureReason,
                    ),
                  );
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: false,
                      downloadStage: DownloadStage.failed,
                      downloadErrorMessage: event.errorMsg,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.failed,
                          message: event.errorMsg,
                        ),
                      ),
                    ),
                  );
                  if (!completer.isCompleted) {
                    completer.complete(
                      _MapDownloadPhaseResult(
                        success: false,
                        fileSize: _cubit.state.downloadedBytes,
                      ),
                    );
                  }
                  break;
                case DownloadMapInitializing():
                  unawaited(
                    _cubit._crashlytics.setContext(
                      downloadStage: 'initializing',
                    ),
                  );
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadedBytes: 0,
                      downloadStage: DownloadStage.initializing,
                      downloadProgress: 0.0,
                      downloadDone: false,
                      clearDownloadTileCount: true,
                      clearDownloadWorkerCount: true,
                      clearDownloadErrorMessage: true,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.active,
                          message: t.createFlight.downloading.preparingMap,
                        ),
                      ),
                    ),
                  );
                  break;
                case DownloadMapComputingTiles():
                  unawaited(
                    _cubit._crashlytics.setContext(
                      downloadStage: 'computing_tiles',
                    ),
                  );
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadStage: DownloadStage.computingTiles,
                      downloadTileCount: event.totalTiles,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.active,
                          message: t.createFlight.downloading
                              .computingTilesWithCount(count: event.totalTiles),
                        ),
                      ),
                    ),
                  );
                  break;
                case DownloadMapStartingWorkers():
                  unawaited(
                    _cubit._crashlytics.setContext(
                      downloadStage: 'starting_workers',
                    ),
                  );
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadStage: DownloadStage.startingWorkers,
                      downloadWorkerCount: event.workerCount,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.active,
                          message:
                              t.createFlight.downloading.preparingForDownload,
                        ),
                      ),
                    ),
                  );
                  break;
                case DownloadMapFinalizing():
                  unawaited(
                    _cubit._crashlytics.setContext(downloadStage: 'finalizing'),
                  );
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadStage: DownloadStage.finalizing,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.active,
                          message: t.createFlight.downloading.finalizing,
                        ),
                      ),
                    ),
                  );
                  break;
                case DownloadMapVerifying():
                  unawaited(
                    _cubit._crashlytics.setContext(downloadStage: 'verifying'),
                  );
                  _cubit._emitState(
                    _cubit.state.copyWith(
                      isDownloading: true,
                      downloadStage: DownloadStage.verifying,
                      downloadSections: _cubit.state.downloadSections.copyWith(
                        map: _cubit.state.downloadSections.map.copyWith(
                          status: DownloadSectionStatus.active,
                          message: t.createFlight.downloading.verifying,
                        ),
                      ),
                    ),
                  );
                  break;
              }
            },
            onDone: () {
              if (!completer.isCompleted) {
                completer.complete(
                  _MapDownloadPhaseResult(
                    success: false,
                    fileSize: _cubit.state.downloadedBytes,
                  ),
                );
              }
            },
          );
      final result = await completer.future;
      await _downloadSubscription?.cancel();
      _downloadSubscription = null;
      return result;
    } catch (e, stackTrace) {
      unawaited(
        _cubit._analytics.log(
          DownloadFailedEvent(
            stage: 'start',
            errorType: e.runtimeType.toString(),
            errorMessage: e.toString(),
            routeLengthKm: routeLengthKm,
            routeSource: route.source,
          ),
        ),
      );
      unawaited(
        _cubit._crashlytics.recordError(
          e,
          stackTrace,
          reason: 'map_download_stream_setup_failed',
        ),
      );
      _cubit._emitState(
        _cubit.state.copyWith(
          isDownloading: false,
          downloadStage: DownloadStage.failed,
          downloadErrorMessage: t.createFlight.errors.failedStartDownload(
            error: e.toString(),
          ),
          downloadSections: _cubit.state.downloadSections.copyWith(
            map: _cubit.state.downloadSections.map.copyWith(
              status: DownloadSectionStatus.failed,
              message: e.toString(),
            ),
          ),
        ),
      );
      return _MapDownloadPhaseResult(
        success: false,
        fileSize: _cubit.state.downloadedBytes,
      );
    }
  }

  Future<void> _rollbackSavedFlightAfterCancel({
    required String flightId,
    String? bundleId,
  }) async {
    try {
      final deleted = await _deleteFlightUseCase(flightId);
      if (deleted && _didConsumePendingFlightUnlock) {
        await _flightUnlockRepository.restoreUnlock();
        _didConsumePendingFlightUnlock = false;
      }
      if (!deleted && !_cubit.isClosed) {
        _cubit._emitState(
          _cubit.state.copyWith(
            downloadErrorMessage: t.createFlight.errors.failedStartDownload(
              error: 'Failed to rollback cancelled download',
            ),
          ),
        );
      }
    } catch (e) {
      if (!_cubit.isClosed) {
        _cubit._emitState(
          _cubit.state.copyWith(
            downloadErrorMessage: t.createFlight.errors.failedStartDownload(
              error: e.toString(),
            ),
          ),
        );
      }
    } finally {
      if (bundleId != null) {
        await _downloadWikipediaArticlesUseCase.cleanupBundleMedia(bundleId);
      }
    }
  }

  String _formatDownloadedMb(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  String _mapDownloadFailureReason(String errorMessage) {
    final normalized = errorMessage.toLowerCase();
    if (normalized.contains('failed to verify mbtiles file') ||
        normalized.contains('mbtiles verification failed')) {
      return 'map_download_failed_mbtiles_verification';
    }
    if (normalized.contains('no internet')) {
      return 'map_download_failed_no_internet';
    }
    if (normalized.contains('tiles downloaded')) {
      return 'map_download_failed_low_tile_coverage';
    }
    if (normalized.contains('canceled')) {
      return 'map_download_failed_canceled';
    }
    return 'map_download_failed';
  }

  String _mapDownloadFailureStage(String errorMessage) {
    final normalized = errorMessage.toLowerCase();
    if (normalized.contains('failed to verify mbtiles file') ||
        normalized.contains('mbtiles verification failed')) {
      return 'failed_verifying_mbtiles';
    }
    if (normalized.contains('tiles downloaded')) {
      return 'failed_tile_coverage';
    }
    if (normalized.contains('no internet')) {
      return 'failed_no_internet';
    }
    if (normalized.contains('canceled')) {
      return 'failed_canceled';
    }
    return 'failed';
  }

  String _contextErrorSnippet(String errorMessage) {
    final compact = errorMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 160) return compact;
    return '${compact.substring(0, 160)}...';
  }
}

class _MapDownloadPhaseResult {
  const _MapDownloadPhaseResult({
    required this.success,
    required this.fileSize,
  });

  final bool success;
  final int fileSize;
}
