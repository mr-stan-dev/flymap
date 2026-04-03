import 'package:equatable/equatable.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';

enum CreateFlightStep {
  departure,
  arrival,
  routeNotSupported,
  mapPreview,
  overview,
  wikipediaArticles,
}

enum DownloadStage {
  idle,
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

class FlightSearchScreenState extends Equatable {
  const FlightSearchScreenState({
    required this.step,
    required this.popularAirports,
    required this.favoriteAirports,
    required this.searchQuery,
    required this.searchResults,
    required this.isSearchLoading,
    required this.selectedDeparture,
    required this.selectedArrival,
    required this.selectedAirportIsFavorite,
    required this.flightRoute,
    required this.flightInfo,
    required this.selectedMapDetailLevel,
    required this.articleCandidates,
    required this.selectedArticleUrls,
    required this.isWikiSuggestionsLoading,
    required this.isPreviewLoading,
    required this.isOverviewLoading,
    required this.isTooLongFlight,
    required this.hasInternetForMapPreview,
    required this.isDownloading,
    required this.downloadProgress,
    required this.downloadedBytes,
    required this.downloadStage,
    required this.articleDownloadCompleted,
    required this.articleDownloadTotal,
    required this.articleDownloadFailed,
    required this.downloadTileCount,
    required this.downloadWorkerCount,
    required this.downloadDone,
    required this.errorMessage,
    required this.downloadErrorMessage,
  });

  factory FlightSearchScreenState.initial() {
    return const FlightSearchScreenState(
      step: CreateFlightStep.departure,
      popularAirports: [],
      favoriteAirports: [],
      searchQuery: '',
      searchResults: [],
      isSearchLoading: false,
      selectedDeparture: null,
      selectedArrival: null,
      selectedAirportIsFavorite: false,
      flightRoute: null,
      flightInfo: FlightInfo.empty,
      selectedMapDetailLevel: MapDetailLevel.basic,
      articleCandidates: [],
      selectedArticleUrls: [],
      isWikiSuggestionsLoading: false,
      isPreviewLoading: false,
      isOverviewLoading: false,
      isTooLongFlight: false,
      hasInternetForMapPreview: true,
      isDownloading: false,
      downloadProgress: 0.0,
      downloadedBytes: 0,
      downloadStage: DownloadStage.idle,
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
  final List<Airport> popularAirports;
  final List<Airport> favoriteAirports;
  final String searchQuery;
  final List<Airport> searchResults;
  final bool isSearchLoading;
  final Airport? selectedDeparture;
  final Airport? selectedArrival;
  final bool selectedAirportIsFavorite;
  final FlightRoute? flightRoute;
  final FlightInfo flightInfo;
  final MapDetailLevel selectedMapDetailLevel;
  final List<WikiArticleCandidate> articleCandidates;
  final List<String> selectedArticleUrls;
  final bool isWikiSuggestionsLoading;
  final bool isPreviewLoading;
  final bool isOverviewLoading;
  final bool isTooLongFlight;
  final bool hasInternetForMapPreview;
  final bool isDownloading;
  final double downloadProgress;
  final int downloadedBytes;
  final DownloadStage downloadStage;
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

  FlightSearchScreenState copyWith({
    CreateFlightStep? step,
    List<Airport>? popularAirports,
    List<Airport>? favoriteAirports,
    String? searchQuery,
    List<Airport>? searchResults,
    bool? isSearchLoading,
    Airport? selectedDeparture,
    bool clearSelectedDeparture = false,
    Airport? selectedArrival,
    bool clearSelectedArrival = false,
    bool? selectedAirportIsFavorite,
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
    bool? isTooLongFlight,
    bool? hasInternetForMapPreview,
    bool? isDownloading,
    double? downloadProgress,
    int? downloadedBytes,
    DownloadStage? downloadStage,
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
    return FlightSearchScreenState(
      step: step ?? this.step,
      popularAirports: popularAirports ?? this.popularAirports,
      favoriteAirports: favoriteAirports ?? this.favoriteAirports,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      isSearchLoading: isSearchLoading ?? this.isSearchLoading,
      selectedDeparture: clearSelectedDeparture
          ? null
          : selectedDeparture ?? this.selectedDeparture,
      selectedArrival: clearSelectedArrival
          ? null
          : selectedArrival ?? this.selectedArrival,
      selectedAirportIsFavorite:
          selectedAirportIsFavorite ?? this.selectedAirportIsFavorite,
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
      isTooLongFlight: isTooLongFlight ?? this.isTooLongFlight,
      hasInternetForMapPreview:
          hasInternetForMapPreview ?? this.hasInternetForMapPreview,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      downloadStage: downloadStage ?? this.downloadStage,
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
    popularAirports,
    favoriteAirports,
    searchQuery,
    searchResults,
    isSearchLoading,
    selectedDeparture,
    selectedArrival,
    selectedAirportIsFavorite,
    flightRoute,
    flightInfo,
    selectedMapDetailLevel,
    articleCandidates,
    selectedArticleUrls,
    isWikiSuggestionsLoading,
    isPreviewLoading,
    isOverviewLoading,
    isTooLongFlight,
    hasInternetForMapPreview,
    isDownloading,
    downloadProgress,
    downloadedBytes,
    downloadStage,
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
