part of '../flight_preview_cubit.dart';

class DownloadFlowDelegate {
  DownloadFlowDelegate(
    this._cubit, {
    required DownloadMapUseCase downloadMapUseCase,
    required DownloadPoiSummariesUseCase downloadPoiSummariesUseCase,
    required DownloadWikipediaArticlesUseCase downloadWikipediaArticlesUseCase,
    required FlightRepository flightRepository,
    required SubscriptionRepository subscriptionRepository,
    required DeleteFlightUseCase deleteFlightUseCase,
  }) : _downloadMapUseCase = downloadMapUseCase,
       _downloadPoiSummariesUseCase = downloadPoiSummariesUseCase,
       _downloadWikipediaArticlesUseCase = downloadWikipediaArticlesUseCase,
       _flightRepository = flightRepository,
       _subscriptionRepository = subscriptionRepository,
       _deleteFlightUseCase = deleteFlightUseCase;

  final FlightPreviewCubit _cubit;
  final DownloadMapUseCase _downloadMapUseCase;
  final DownloadPoiSummariesUseCase _downloadPoiSummariesUseCase;
  final DownloadWikipediaArticlesUseCase _downloadWikipediaArticlesUseCase;
  final FlightRepository _flightRepository;
  final SubscriptionRepository _subscriptionRepository;
  final DeleteFlightUseCase _deleteFlightUseCase;

  StreamSubscription? _downloadSubscription;
  bool _downloadCancelled = false;
  String? _savedFlightIdDuringDownload;
  String? _activeArticleBundleId;

  int get _freeWikiArticlesSelectionLimit =>
      ProLimits.freeWikiArticlesSelectionLimit;

  String _articleBundleId(FlightRoute route) =>
      '${route.routeCode}_${route.departure.displayCode}_${route.arrival.displayCode}';

  int _poiDownloadTargetCount(List<RoutePoiSummary> pois) =>
      pois.where((poi) => poi.qid.trim().isNotEmpty).length;

  Future<void> startDownload() async {
    if (_cubit.state.isDownloading) return;
    final route = _cubit.state.flightRoute;
    if (route == null) return;
    final isPro = _subscriptionRepository.currentStatus.isPro;

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
    final poiToDownloadCount = _poiDownloadTargetCount(
      _cubit.state.flightInfo.poi,
    );
    final flightId = DownloadMapUseCase.flightIdForRoute(route);
    final articleBundleId = _articleBundleId(route);
    _activeArticleBundleId = articleBundleId;
    final initialSections = DownloadSectionsState(
      map: DownloadSectionState.initial().copyWith(
        status: DownloadSectionStatus.active,
        message: t.createFlight.downloading.preparingMap,
      ),
      poi: poiToDownloadCount <= 0
          ? DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.skipped,
            )
          : DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.pending,
              total: poiToDownloadCount,
            ),
      articles: selectedUrls.isEmpty
          ? DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.skipped,
            )
          : DownloadSectionState.initial().copyWith(
              status: DownloadSectionStatus.pending,
              total: selectedUrls.length,
            ),
    );
    final hasArticlePhase = selectedUrls.isNotEmpty;
    var enrichedInfo = _cubit.state.flightInfo.copyWith(articles: const []);
    final effectiveMaxZoom = MapDownloadConfig.resolveMaxZoom(
      distanceKm: route.distanceInKm,
      detailLevel: _cubit.state.selectedMapDetailLevel,
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
        poiDownloadTotal: poiToDownloadCount,
        poiDownloadFailed: 0,
        articleDownloadCompleted: 0,
        articleDownloadTotal: selectedUrls.length,
        articleDownloadFailed: 0,
        clearDownloadTileCount: true,
        clearDownloadWorkerCount: true,
        downloadDone: false,
        clearDownloadErrorMessage: true,
        clearErrorMessage: true,
      ),
    );
    unawaited(
      _cubit._analytics.log(
        DownloadStartedEvent(
          routeLengthKm: routeLengthKm,
          mapDetail: _cubit.state.selectedMapDetailLevel,
          articlesSelectedCount: selectedUrls.length,
          isProUser: isPro,
        ),
      ),
    );
    unawaited(
      _cubit._crashlytics.setContext(
        screen: 'create_flight_download',
        routeLengthKm: routeLengthKm.round(),
        mapDetail: _cubit.state.selectedMapDetailLevel.name,
        articlesSelectedCount: selectedUrls.length,
        downloadStage: 'initializing',
      ),
    );

    final mapPhase = await _runMapDownloadPhase(
      route: route,
      infoForSave: enrichedInfo,
      effectiveMaxZoom: effectiveMaxZoom,
      routeLengthKm: routeLengthKm,
    );
    if (!mapPhase.success || _downloadCancelled || _cubit.isClosed) {
      return;
    }

    _savedFlightIdDuringDownload = flightId;
    var poiHadIssues = false;
    var articleHadIssues = false;

    if (poiToDownloadCount > 0) {
      _cubit._emitState(
        _cubit.state.copyWith(
          isDownloading: true,
          downloadStage: DownloadStage.downloadingPoi,
          downloadSections: _cubit.state.downloadSections.copyWith(
            poi: _cubit.state.downloadSections.poi.copyWith(
              status: DownloadSectionStatus.active,
              message: t.createFlight.downloading.preparingPoi,
            ),
          ),
        ),
      );
      try {
        final result = await _downloadPoiSummariesUseCase.call(
          pois: enrichedInfo.poi,
          preferredLanguageCode: LocaleSettings.currentLocale.languageCode,
          onProgress: (progress) {
            if (_downloadCancelled || _cubit.isClosed) return;
            _cubit._emitState(
              _cubit.state.copyWith(
                isDownloading: true,
                downloadStage: DownloadStage.downloadingPoi,
                poiDownloadCompleted: progress.completed,
                poiDownloadTotal: progress.total,
                poiDownloadFailed: progress.failed,
                downloadProgress: 0.0,
                downloadDone: false,
                downloadSections: _cubit.state.downloadSections.copyWith(
                  poi: _cubit.state.downloadSections.poi.copyWith(
                    status: DownloadSectionStatus.active,
                    completed: progress.completed,
                    total: progress.total,
                    failed: progress.failed,
                    message: progress.failed > 0
                        ? t.createFlight.downloading.poiProgressWithFailed(
                            completed: progress.completed,
                            total: progress.total,
                            failed: progress.failed,
                          )
                        : t.createFlight.downloading.poiProgress(
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

        enrichedInfo = enrichedInfo.copyWith(poi: result.pois);
        final persisted = await _flightRepository.updateFlightInfo(
          flightId: flightId,
          info: enrichedInfo,
        );
        final poiFailedCount =
            (result.failedCount + (!persisted ? 1 : 0))
                .clamp(0, poiToDownloadCount)
                .toInt();
        final poiSucceededCount = poiToDownloadCount - poiFailedCount;
        unawaited(
          _cubit._analytics.log(
            PoiDownloadCompletedEvent(
              routeLengthKm: routeLengthKm,
              totalCount: poiToDownloadCount,
              succeededCount: poiSucceededCount,
              failedCount: poiFailedCount,
              isProUser: isPro,
            ),
          ),
        );
        poiHadIssues = result.failedCount > 0 || !persisted;
        _cubit._emitState(
          _cubit.state.copyWith(
            isDownloading: true,
            downloadStage: hasArticlePhase
                ? DownloadStage.downloadingArticles
                : DownloadStage.completed,
            poiDownloadCompleted: poiToDownloadCount,
            poiDownloadTotal: poiToDownloadCount,
            poiDownloadFailed: result.failedCount,
            downloadProgress: 0.0,
            downloadSections: _cubit.state.downloadSections.copyWith(
              poi: _cubit.state.downloadSections.poi.copyWith(
                status: poiHadIssues
                    ? DownloadSectionStatus.completedWithIssues
                    : DownloadSectionStatus.completed,
                completed: poiToDownloadCount,
                total: poiToDownloadCount,
                failed: poiFailedCount,
                message: poiHadIssues
                    ? t.createFlight.downloading.completedWithIssues
                    : t.createFlight.downloading.completed,
              ),
            ),
          ),
        );
      } catch (e, stackTrace) {
        _cubit._logger.error(
          'POI summary download failed; continuing with map/article download: $e',
        );
        unawaited(
          _cubit._crashlytics.recordError(
            e,
            stackTrace,
            reason: 'poi_summary_download_failed',
          ),
        );
        if (_downloadCancelled || _cubit.isClosed) return;
        poiHadIssues = true;
        unawaited(
          _cubit._analytics.log(
            PoiDownloadCompletedEvent(
              routeLengthKm: routeLengthKm,
              totalCount: poiToDownloadCount,
              succeededCount: 0,
              failedCount: poiToDownloadCount,
              isProUser: isPro,
            ),
          ),
        );
        _cubit._emitState(
          _cubit.state.copyWith(
            isDownloading: true,
            downloadStage: hasArticlePhase
                ? DownloadStage.downloadingArticles
                : DownloadStage.completed,
            poiDownloadCompleted: poiToDownloadCount,
            poiDownloadTotal: poiToDownloadCount,
            poiDownloadFailed: poiToDownloadCount,
            downloadProgress: 0.0,
            downloadSections: _cubit.state.downloadSections.copyWith(
              poi: _cubit.state.downloadSections.poi.copyWith(
                status: DownloadSectionStatus.failed,
                completed: poiToDownloadCount,
                total: poiToDownloadCount,
                failed: poiToDownloadCount,
                message: t.createFlight.downloading.failed,
              ),
            ),
          ),
        );
      }
    }

    if (_downloadCancelled || _cubit.isClosed) return;

    var downloadedArticles = const <FlightArticle>[];
    if (hasArticlePhase) {
      _cubit._emitState(
        _cubit.state.copyWith(
          isDownloading: true,
          downloadStage: DownloadStage.downloadingArticles,
          downloadSections: _cubit.state.downloadSections.copyWith(
            articles: _cubit.state.downloadSections.articles.copyWith(
              status: DownloadSectionStatus.active,
              message: t.createFlight.downloading.preparingArticles,
            ),
          ),
        ),
      );
      try {
        final result = await _downloadWikipediaArticlesUseCase.call(
          bundleId: articleBundleId,
          articleUrls: selectedUrls,
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

        downloadedArticles = result.articles;
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
            articleDownloadCompleted: selectedUrls.length,
            articleDownloadTotal: selectedUrls.length,
            articleDownloadFailed: result.failedCount,
            downloadProgress: 0.0,
            downloadSections: _cubit.state.downloadSections.copyWith(
              articles: _cubit.state.downloadSections.articles.copyWith(
                status: articleHadIssues
                    ? DownloadSectionStatus.completedWithIssues
                    : DownloadSectionStatus.completed,
                completed: selectedUrls.length,
                total: selectedUrls.length,
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
            articleDownloadCompleted: selectedUrls.length,
            articleDownloadTotal: selectedUrls.length,
            articleDownloadFailed: selectedUrls.length,
            downloadProgress: 0.0,
            errorMessage: t.createFlight.errors.someArticlesFailed,
            downloadSections: _cubit.state.downloadSections.copyWith(
              articles: _cubit.state.downloadSections.articles.copyWith(
                status: DownloadSectionStatus.failed,
                completed: selectedUrls.length,
                total: selectedUrls.length,
                failed: selectedUrls.length,
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
        clearDownloadErrorMessage: true,
      ),
    );
  }

  void cancelDownload() {
    if (!_cubit.state.isDownloading) return;
    _downloadCancelled = true;
    final rollbackFlightId = _savedFlightIdDuringDownload;
    final bundleId = _activeArticleBundleId;
    _downloadPoiSummariesUseCase.cancel();
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
    _downloadPoiSummariesUseCase.cancel();
    _downloadWikipediaArticlesUseCase.cancel();
    _downloadMapUseCase.cancel();
    unawaited(_downloadSubscription?.cancel());
  }

  Future<_MapDownloadPhaseResult> _runMapDownloadPhase({
    required FlightRoute route,
    required FlightInfo infoForSave,
    required int effectiveMaxZoom,
    required double routeLengthKm,
  }) async {
    final completer = Completer<_MapDownloadPhaseResult>();
    try {
      _downloadSubscription = _downloadMapUseCase
          .call(
            flightRoute: route,
            flightInfo: infoForSave,
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
                  unawaited(
                    _cubit._analytics.log(
                      DownloadFailedEvent(
                        stage: 'map_download',
                        errorType: 'map_download_error',
                        errorMessage: event.errorMsg,
                        routeLengthKm: routeLengthKm,
                      ),
                    ),
                  );
                  unawaited(
                    _cubit._crashlytics.setContext(downloadStage: 'failed'),
                  );
                  unawaited(
                    _cubit._crashlytics.recordError(
                      Exception(event.errorMsg),
                      StackTrace.current,
                      reason: 'map_download_failed',
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
}

class _MapDownloadPhaseResult {
  const _MapDownloadPhaseResult({
    required this.success,
    required this.fileSize,
  });

  final bool success;
  final int fileSize;
}
