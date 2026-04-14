import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/app_analytics_initializer.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/crashlytics/app_crashlytics_initializer.dart';
import 'package:flymap/data/api/feedback_api.dart';
import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/flight_poi_repository_impl.dart';
import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/local/learn_pack_local_db.dart';
import 'package:flymap/data/local/learn_repository_impl.dart';
import 'package:flymap/data/local/places_wiki_local_data_source.dart';
import 'package:flymap/data/local/mappers/flight_db_mapper.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/data/route/great_circle_route_provider.dart';
import 'package:flymap/data/wiki/wikipedia_article_client.dart';
import 'package:flymap/data/wiki/wikimedia_api_client.dart';
import 'package:flymap/data/wiki/wikidata_wikipedia_preview_repository.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_repository.dart';
import 'package:flymap/rating/rate_store_launcher.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/flight_poi_repository.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/revenuecat_client.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';
import 'package:flymap/subscription/subscription_status_cache.dart';
import 'package:flymap/usecase/delete_flight_use_case.dart';
import 'package:flymap/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_poi_summaries_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:flymap/usecase/get_flight_poi_use_case.dart';
import 'package:flymap/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/usecase/get_poi_wiki_preview_use_case.dart';
import 'package:flymap/usecase/submit_feedback_use_case.dart';
import 'package:flymap/usecase/toggle_learn_article_favorite_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

class DiModule {
  final i = GetIt.I;

  void register() {
    i.registerLazySingleton<AppAnalytics>(() => FirebaseAppAnalytics());
    i.registerLazySingleton<AppAnalyticsInitializer>(
      () => AppAnalyticsInitializer(analytics: i.get<AppAnalytics>()),
    );
    i.registerLazySingleton<AppCrashlytics>(() => FirebaseAppCrashlytics());
    i.registerLazySingleton<AppCrashlyticsInitializer>(
      () => AppCrashlyticsInitializer(crashlytics: i.get<AppCrashlytics>()),
    );

    i.registerLazySingleton<AirportsDatabase>(() => AirportsDatabase.instance);

    // Register database
    i.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

    i.registerFactory<FlightInfoApiMapper>(() => FlightInfoApiMapper());

    i.registerFactory<FlightInfoApi>(() => FlightInfoApi(apiMapper: i.get()));

    i.registerFactory<FlightDbMapper>(() => FlightDbMapper());

    i.registerLazySingleton<FlightsDBService>(
      () => FlightsDBService(database: i.get(), flightMapper: i.get()),
    );

    i.registerFactory<FlightRouteProvider>(() => GreatCircleRouteProvider());

    // Connectivity checker
    i.registerLazySingleton<ConnectivityChecker>(
      () => const ConnectivityChecker(),
    );
    i.registerLazySingleton<MapAssetCacheService>(() => MapAssetCacheService());

    i.registerLazySingleton<DownloadMapUseCase>(
      () => DownloadMapUseCase(
        service: GetIt.I.get(),
        connectivity: GetIt.I.get(),
      ),
    );
    i.registerLazySingleton<WikimediaUserAgentProvider>(
      () => PackageInfoWikimediaUserAgentProvider(),
    );
    i.registerLazySingleton<http.Client>(() => http.Client());
    i.registerLazySingleton<RatePromptRepository>(
      () => SharedPrefsRatePromptRepository(),
    );
    i.registerLazySingleton<RatePromptPolicyService>(
      () => DefaultRatePromptPolicyService(repository: i.get()),
    );
    i.registerLazySingleton<RateStoreLauncher>(
      () => DefaultRateStoreLauncher(httpClient: i.get()),
    );
    i.registerLazySingleton<FeedbackApi>(() => FeedbackApi());
    i.registerLazySingleton<SubmitFeedbackUseCase>(
      () => DefaultSubmitFeedbackUseCase(feedbackApi: i.get()),
    );
    i.registerLazySingleton<WikimediaApiClient>(
      () => WikimediaApiClient(httpClient: i.get(), userAgentProvider: i.get()),
    );
    i.registerLazySingleton<WikipediaArticleClient>(
      () => WikipediaArticleClient(apiClient: i.get()),
    );
    i.registerLazySingleton<DownloadWikipediaArticlesUseCase>(
      () => DownloadWikipediaArticlesUseCase(articleClient: GetIt.I.get()),
    );
    i.registerLazySingleton<GetFlightInfoUseCase>(
      () => GetFlightInfoUseCase(flightInfoApi: GetIt.I.get()),
    );

    i.registerLazySingleton<FlightRepository>(
      () => FlightRepository(service: GetIt.I.get()),
    );
    i.registerLazySingleton<DeleteFlightUseCase>(
      () => DeleteFlightUseCase(service: GetIt.I.get()),
    );

    i.registerLazySingleton<FavoriteAirportsRepository>(
      () => FavoriteAirportsRepository(),
    );
    i.registerLazySingleton<PlacesWikiLocalDataSource>(
      () => PlacesWikiLocalDataSource(),
    );
    i.registerLazySingleton<FlightPOIRepository>(
      () => LocalFlightPOIRepository(localDataSource: i.get()),
    );
    i.registerLazySingleton<GetFlightPOIUseCase>(
      () => GetFlightPOIUseCase(repository: i.get()),
    );
    i.registerLazySingleton<PoiWikiPreviewRepository>(
      () => WikidataWikipediaPreviewRepository(apiClient: i.get()),
    );
    i.registerLazySingleton<GetPoiWikiPreviewUseCase>(
      () => GetPoiWikiPreviewUseCase(repository: i.get()),
    );
    i.registerLazySingleton<DownloadPoiSummariesUseCase>(
      () => DownloadPoiSummariesUseCase(repository: i.get()),
    );

    i.registerLazySingleton<OnboardingRepository>(() => OnboardingRepository());

    i.registerLazySingleton<LearnPackLocalDb>(() => LearnPackLocalDb());
    i.registerLazySingleton<LearnRepository>(
      () => LocalLearnRepository(localDb: i.get()),
    );
    i.registerLazySingleton<LearnArticleProgressRepository>(
      () => SharedPrefsLearnArticleProgressRepository(),
    );
    i.registerLazySingleton<GetLearnCategoriesUseCase>(
      () => GetLearnCategoriesUseCase(repository: i.get()),
    );
    i.registerLazySingleton<GetLearnCategoryArticlesUseCase>(
      () => GetLearnCategoryArticlesUseCase(repository: i.get()),
    );
    i.registerLazySingleton<GetLearnArticleContentUseCase>(
      () => GetLearnArticleContentUseCase(repository: i.get()),
    );
    i.registerLazySingleton<GetLearnArticleProgressUseCase>(
      () => GetLearnArticleProgressUseCase(repository: i.get()),
    );
    i.registerLazySingleton<ToggleLearnArticleFavoriteUseCase>(
      () => ToggleLearnArticleFavoriteUseCase(repository: i.get()),
    );
    i.registerLazySingleton<MarkLearnArticleSeenUseCase>(
      () => MarkLearnArticleSeenUseCase(repository: i.get()),
    );
    i.registerLazySingleton<CanOpenLearnArticleUseCase>(
      () => CanOpenLearnArticleUseCase(repository: i.get()),
    );

    i.registerLazySingleton<RevenueCatEnvConfig>(
      RevenueCatEnvConfig.fromEnvironment,
    );
    i.registerLazySingleton<RevenueCatClient>(
      () => PurchasesRevenueCatClient(),
    );
    i.registerLazySingleton<SubscriptionStatusCache>(
      () => SharedPrefsSubscriptionStatusCache(),
    );
    i.registerLazySingleton<SubscriptionRepository>(
      () => RevenueCatSubscriptionRepository(
        client: i.get(),
        config: i.get(),
        statusCache: i.get(),
      ),
    );
  }
}
