import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';

enum CreateFlightStep {
  routeNotSupported,
  mapPreview,
  overview,
  wikipediaArticles,
}

enum DownloadStage {
  idle,
  downloadingPoi,
  downloadingArticles,
  initializing,
  computingTiles,
  startingWorkers,
  downloading,
  finalizing,
  verifying,
  completed,
  failed,
}

enum DownloadSectionStatus {
  pending,
  active,
  completed,
  completedWithIssues,
  failed,
  skipped,
}

class DownloadSectionState extends Equatable {
  const DownloadSectionState({
    required this.status,
    required this.completed,
    required this.total,
    required this.failed,
    required this.progress,
    required this.downloadedBytes,
    required this.message,
  });

  const DownloadSectionState.initial()
    : status = DownloadSectionStatus.pending,
      completed = 0,
      total = 0,
      failed = 0,
      progress = 0,
      downloadedBytes = 0,
      message = null;

  final DownloadSectionStatus status;
  final int completed;
  final int total;
  final int failed;
  final double progress;
  final int downloadedBytes;
  final String? message;

  DownloadSectionState copyWith({
    DownloadSectionStatus? status,
    int? completed,
    int? total,
    int? failed,
    double? progress,
    int? downloadedBytes,
    String? message,
    bool clearMessage = false,
  }) {
    return DownloadSectionState(
      status: status ?? this.status,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      failed: failed ?? this.failed,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    completed,
    total,
    failed,
    progress,
    downloadedBytes,
    message,
  ];
}

class DownloadSectionsState extends Equatable {
  const DownloadSectionsState({
    required this.map,
    required this.poi,
    required this.articles,
  });

  const DownloadSectionsState.initial()
    : map = const DownloadSectionState.initial(),
      poi = const DownloadSectionState.initial(),
      articles = const DownloadSectionState.initial();

  final DownloadSectionState map;
  final DownloadSectionState poi;
  final DownloadSectionState articles;

  DownloadSectionsState copyWith({
    DownloadSectionState? map,
    DownloadSectionState? poi,
    DownloadSectionState? articles,
  }) {
    return DownloadSectionsState(
      map: map ?? this.map,
      poi: poi ?? this.poi,
      articles: articles ?? this.articles,
    );
  }

  @override
  List<Object?> get props => [map, poi, articles];
}

class FlightPreviewState extends Equatable {
  const FlightPreviewState({
    required this.step,
    required this.flightRoute,
    required this.flightInfo,
    required this.selectedMapDetailLevel,
    required this.articleCandidates,
    required this.selectedArticleUrls,
    required this.isWikiSuggestionsLoading,
    required this.isPreviewLoading,
    required this.isOverviewLoading,
    required this.hasInternetForMapPreview,
    required this.downloadSections,
    required this.isDownloading,
    required this.downloadProgress,
    required this.downloadedBytes,
    required this.downloadStage,
    required this.poiDownloadCompleted,
    required this.poiDownloadTotal,
    required this.poiDownloadFailed,
    required this.articleDownloadCompleted,
    required this.articleDownloadTotal,
    required this.articleDownloadFailed,
    required this.downloadTileCount,
    required this.downloadWorkerCount,
    required this.downloadDone,
    required this.errorMessage,
    required this.downloadErrorMessage,
  });

  factory FlightPreviewState.initial() {
    return const FlightPreviewState(
      step: CreateFlightStep.mapPreview,
      flightRoute: null,
      flightInfo: FlightInfo.empty,
      selectedMapDetailLevel: MapDetailLevel.basic,
      articleCandidates: [],
      selectedArticleUrls: [],
      isWikiSuggestionsLoading: false,
      isPreviewLoading: true,
      isOverviewLoading: false,
      hasInternetForMapPreview: true,
      downloadSections: DownloadSectionsState.initial(),
      isDownloading: false,
      downloadProgress: 0.0,
      downloadedBytes: 0,
      downloadStage: DownloadStage.idle,
      poiDownloadCompleted: 0,
      poiDownloadTotal: 0,
      poiDownloadFailed: 0,
      articleDownloadCompleted: 0,
      articleDownloadTotal: 0,
      articleDownloadFailed: 0,
      downloadTileCount: null,
      downloadWorkerCount: null,
      downloadDone: false,
      errorMessage: null,
      downloadErrorMessage: null,
    );
  }

  final CreateFlightStep step;
  final FlightRoute? flightRoute;
  final FlightInfo flightInfo;
  final MapDetailLevel selectedMapDetailLevel;
  final List<WikiArticleCandidate> articleCandidates;
  final List<String> selectedArticleUrls;
  final bool isWikiSuggestionsLoading;
  final bool isPreviewLoading;
  final bool isOverviewLoading;
  final bool hasInternetForMapPreview;
  final DownloadSectionsState downloadSections;
  final bool isDownloading;
  final double downloadProgress;
  final int downloadedBytes;
  final DownloadStage downloadStage;
  final int poiDownloadCompleted;
  final int poiDownloadTotal;
  final int poiDownloadFailed;
  final int articleDownloadCompleted;
  final int articleDownloadTotal;
  final int articleDownloadFailed;
  final int? downloadTileCount;
  final int? downloadWorkerCount;
  final bool downloadDone;
  final String? errorMessage;
  final String? downloadErrorMessage;

  bool get canContinueFromMap =>
      flightRoute != null && !isPreviewLoading && !isDownloading;

  FlightPreviewState copyWith({
    CreateFlightStep? step,
    FlightRoute? flightRoute,
    bool clearFlightRoute = false,
    FlightInfo? flightInfo,
    MapDetailLevel? selectedMapDetailLevel,
    List<WikiArticleCandidate>? articleCandidates,
    List<String>? selectedArticleUrls,
    bool clearSelectedArticleUrls = false,
    bool? isWikiSuggestionsLoading,
    bool? isPreviewLoading,
    bool? isOverviewLoading,
    bool? hasInternetForMapPreview,
    DownloadSectionsState? downloadSections,
    bool? isDownloading,
    double? downloadProgress,
    int? downloadedBytes,
    DownloadStage? downloadStage,
    int? poiDownloadCompleted,
    int? poiDownloadTotal,
    int? poiDownloadFailed,
    int? articleDownloadCompleted,
    int? articleDownloadTotal,
    int? articleDownloadFailed,
    int? downloadTileCount,
    bool clearDownloadTileCount = false,
    int? downloadWorkerCount,
    bool clearDownloadWorkerCount = false,
    bool? downloadDone,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? downloadErrorMessage,
    bool clearDownloadErrorMessage = false,
  }) {
    return FlightPreviewState(
      step: step ?? this.step,
      flightRoute: clearFlightRoute ? null : flightRoute ?? this.flightRoute,
      flightInfo: flightInfo ?? this.flightInfo,
      selectedMapDetailLevel:
          selectedMapDetailLevel ?? this.selectedMapDetailLevel,
      articleCandidates: articleCandidates ?? this.articleCandidates,
      selectedArticleUrls: clearSelectedArticleUrls
          ? const []
          : selectedArticleUrls ?? this.selectedArticleUrls,
      isWikiSuggestionsLoading:
          isWikiSuggestionsLoading ?? this.isWikiSuggestionsLoading,
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      hasInternetForMapPreview:
          hasInternetForMapPreview ?? this.hasInternetForMapPreview,
      downloadSections: downloadSections ?? this.downloadSections,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      downloadStage: downloadStage ?? this.downloadStage,
      poiDownloadCompleted: poiDownloadCompleted ?? this.poiDownloadCompleted,
      poiDownloadTotal: poiDownloadTotal ?? this.poiDownloadTotal,
      poiDownloadFailed: poiDownloadFailed ?? this.poiDownloadFailed,
      articleDownloadCompleted:
          articleDownloadCompleted ?? this.articleDownloadCompleted,
      articleDownloadTotal: articleDownloadTotal ?? this.articleDownloadTotal,
      articleDownloadFailed:
          articleDownloadFailed ?? this.articleDownloadFailed,
      downloadTileCount: clearDownloadTileCount
          ? null
          : downloadTileCount ?? this.downloadTileCount,
      downloadWorkerCount: clearDownloadWorkerCount
          ? null
          : downloadWorkerCount ?? this.downloadWorkerCount,
      downloadDone: downloadDone ?? this.downloadDone,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      downloadErrorMessage: clearDownloadErrorMessage
          ? null
          : downloadErrorMessage ?? this.downloadErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    step,
    flightRoute,
    flightInfo,
    selectedMapDetailLevel,
    articleCandidates,
    selectedArticleUrls,
    isWikiSuggestionsLoading,
    isPreviewLoading,
    isOverviewLoading,
    hasInternetForMapPreview,
    downloadSections,
    isDownloading,
    downloadProgress,
    downloadedBytes,
    downloadStage,
    poiDownloadCompleted,
    poiDownloadTotal,
    poiDownloadFailed,
    articleDownloadCompleted,
    articleDownloadTotal,
    articleDownloadFailed,
    downloadTileCount,
    downloadWorkerCount,
    downloadDone,
    errorMessage,
    downloadErrorMessage,
  ];
}
