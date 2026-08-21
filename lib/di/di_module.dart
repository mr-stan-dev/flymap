import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/app_analytics_context.dart';
import 'package:flymap/analytics/app_analytics_initializer.dart';
import 'package:flymap/analytics/composite_app_analytics.dart';
import 'package:flymap/analytics/posthog_app_analytics.dart';
import 'package:flymap/analytics/posthog_client.dart';
import 'package:flymap/analytics/posthog_env_config.dart';
import 'package:flymap/auth/app_auth_repository.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/crashlytics/app_crashlytics_initializer.dart';
import 'package:flymap/experiments/onboarding_experiment_service.dart';
import 'package:flymap/data/api/feedback_api.dart';
import 'package:flymap/data/api/firebase_weather_forecast_api.dart';
import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/data/api/flight_number_search_api.dart';
import 'package:flymap/data/api/upcoming_flight_search_api.dart';
import 'package:flymap/data/api/mapbox_env_config.dart';
import 'package:flymap/data/api/flight_route_preview_api.dart';
import 'package:flymap/data/api/flight_route_search_api.dart';
import 'package:flymap/data/api/mapbox_raster_tile_api.dart';
import 'package:flymap/data/api/mapbox_static_image_api.dart';
import 'package:flymap/data/flight_video/media_gallery_saver.dart';
import 'package:flymap/data/flight_video/video_encoder.dart';
import 'package:flymap/data/api/route_overview_api.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/data/gps_data_provider.dart';
import 'package:flymap/data/map_asset_cache_service.dart';
import 'package:flymap/data/local/airport_timezone_service.dart';
import 'package:flymap/domain/provider/weather_forecast_provider.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/share/weather_share_service.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/airlines_database.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/route_map_image_store.dart';
import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/local/learn_pack_local_db.dart';
import 'package:flymap/data/location/app_location_client.dart';
import 'package:flymap/data/location/app_location_service.dart';
import 'package:flymap/data/location/geolocator_app_location_client.dart';
import 'package:flymap/data/local/learn_repository_impl.dart';
import 'package:flymap/data/local/migrations/flights_db_migration.dart';
import 'package:flymap/data/local/migrations/flights_db_migration_runner.dart';
import 'package:flymap/data/local/migrations/flights_db_migration_v1_to_v2.dart';
import 'package:flymap/data/local/mappers/flight_db_mapper.dart';
import 'package:flymap/data/mappers/route_overview_api_mapper.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/local/flight_weather_store.dart';
import 'package:flymap/data/notifications/flight_notification_scheduler.dart';
import 'package:flymap/data/notifications/notification_permission_service.dart';
import 'package:flymap/repository/forecast_notification_prefs.dart';
import 'package:flymap/data/wiki/wikipedia_article_client.dart';
import 'package:flymap/data/wiki/wikimedia_api_client.dart';
import 'package:flymap/data/wiki/wikidata_wikipedia_preview_repository.dart';
import 'package:flymap/rating/app_share_service.dart';
import 'package:flymap/rating/native_review_requester.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_repository.dart';
import 'package:flymap/rating/rate_store_launcher.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/repository/home_area_overview_repository.dart';
import 'package:flymap/repository/route_overview_repository.dart';
import 'package:flymap/repository/settings_repository.dart';
import 'package:flymap/repository/sky_camera_media_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/video_avatar_repository.dart';
import 'package:flymap/repository/user_flight_prefs_repository.dart';
import 'package:flymap/repository/flight_search_repository.dart';

import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:flymap/subscription/revenuecat_client.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';
import 'package:flymap/subscription/revenuecat_identity_migration_store.dart';
import 'package:flymap/subscription/subscription_status_cache.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:flymap/domain/usecase/complete_flight_use_case.dart';
import 'package:flymap/domain/usecase/auto_complete_stale_in_progress_flights_use_case.dart';
import 'package:flymap/domain/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/domain/usecase/download_map_use_case.dart';
import 'package:flymap/domain/usecase/download_region_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/domain/usecase/search_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/search_upcoming_flights_by_number_use_case.dart';
import 'package:flymap/domain/usecase/build_flight_route_preview_use_case.dart';
import 'package:flymap/domain/usecase/generate_flight_video_use_case.dart';
import 'package:flymap/domain/usecase/generate_share_image_use_case.dart';
import 'package:flymap/domain/usecase/search_flights_by_route_use_case.dart';

import 'package:flymap/domain/usecase/get_place_info_use_case.dart';
import 'package:flymap/domain/usecase/fetch_flight_weather_use_case.dart';
import 'package:flymap/domain/usecase/get_route_overview_use_case.dart';
import 'package:flymap/domain/usecase/get_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/domain/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/domain/usecase/start_flight_use_case.dart';
import 'package:flymap/domain/usecase/submit_feedback_use_case.dart';
import 'package:flymap/domain/usecase/toggle_learn_article_favorite_use_case.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/i18n/app_localization.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_cubit.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_export_service.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_session_factory.dart';
import 'package:flymap/ui/screens/sky_camera/flymap_sky_camera_share_service.dart';
import 'package:flymap/ui/screens/sky_camera/sky_camera_video_rendition_service.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_review/in_app_review.dart';

class DiModule {
  final i = GetIt.I;

  void register() {
    i.registerLazySingleton<AppAnalyticsContextStore>(
      () => AppAnalyticsContextStore(),
    );
    i.registerLazySingleton<PostHogEnvConfig>(PostHogEnvConfig.fromEnvironment);
    i.registerLazySingleton<PostHogAnalyticsClient>(
      () => PackagePostHogAnalyticsClient(),
    );
    i.registerLazySingleton<OnboardingExperimentService>(
      () => PostHogOnboardingExperimentService(
        postHog: i.get<PostHogAnalyticsClient>(),
      ),
    );
    i.registerLazySingleton<AppAnalytics>(
      () => CompositeAppAnalytics(
        sinks: <AppAnalytics>[
          FirebaseAppAnalytics(),
          PostHogAppAnalytics(
            config: i.get<PostHogEnvConfig>(),
            client: i.get<PostHogAnalyticsClient>(),
          ),
        ],
      ),
    );
    i.registerLazySingleton<AppAnalyticsInitializer>(
      () => AppAnalyticsInitializer(
        analytics: i.get<AppAnalytics>(),
        authRepository: i.get<AppAuthRepository>(),
        contextStore: i.get<AppAnalyticsContextStore>(),
      ),
    );
    i.registerLazySingleton<AppCrashlytics>(() => FirebaseAppCrashlytics());
    i.registerLazySingleton<AppCrashlyticsInitializer>(
      () => AppCrashlyticsInitializer(crashlytics: i.get<AppCrashlytics>()),
    );
    i.registerLazySingleton<AppAuthRepository>(
      () => FirebaseAppAuthRepository(),
    );

    i.registerLazySingleton<AirportsDatabase>(() => AirportsDatabase.instance);
    i.registerLazySingleton<AirlinesDatabase>(() => AirlinesDatabase.instance);

    // Register database
    i.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);
    i.registerLazySingleton<List<FlightsDbMigration>>(
      () => <FlightsDbMigration>[FlightsDbMigrationV1ToV2(database: i.get())],
    );
    i.registerLazySingleton<FlightsDbMigrationRunner>(
      () => FlightsDbMigrationRunner(
        database: i.get(),
        migrations: i.get<List<FlightsDbMigration>>(),
        crashlytics: i.get(),
      ),
    );

    i.registerFactory<FlightInfoApiMapper>(() => FlightInfoApiMapper());

    i.registerFactory<FlightInfoApi>(() => FlightInfoApi(apiMapper: i.get()));

    i.registerFactory<FlightDbMapper>(() => FlightDbMapper());

    i.registerLazySingleton<FlightsDBService>(
      () => FlightsDBService(database: i.get(), flightMapper: i.get()),
    );

    i.registerFactory<RouteOverviewApiMapper>(() => RouteOverviewApiMapper());
    i.registerLazySingleton<RouteOverviewApi>(() => RouteOverviewApi());
    i.registerLazySingleton<FlightNumberSearchApi>(
      () => FlightNumberSearchApi(),
    );
    i.registerLazySingleton<UpcomingFlightSearchApi>(
      () => UpcomingFlightSearchApi(),
    );
    i.registerLazySingleton<FlightRouteSearchApi>(() => FlightRouteSearchApi());
    i.registerLazySingleton<WeatherForecastProvider>(
      () => FirebaseWeatherForecastApi(),
    );
    i.registerLazySingleton<AirportTimezoneService>(
      () => AirportTimezoneService(airportsDatabase: i.get()),
    );
    i.registerLazySingleton<FetchFlightWeatherUseCase>(
      () => FetchFlightWeatherUseCase(
        provider: i.get(),
        timezoneService: i.get(),
      ),
    );
    i.registerLazySingleton<WeatherShareService>(
      () => WeatherShareService(
        mapApi: i.get(),
        encoder: i.get(),
        imageStore: i.get(),
      ),
    );
    i.registerLazySingleton<FlightRoutePreviewApi>(
      () => FlightRoutePreviewApi(),
    );
    i.registerLazySingleton<RouteOverviewRepository>(
      () => ApiRouteOverviewRepository(api: i.get(), mapper: i.get()),
    );
    i.registerLazySingleton<HomeAreaOverviewRepository>(
      () => ApiHomeAreaOverviewRepository(api: i.get()),
    );
    i.registerLazySingleton<GetRouteOverviewUseCase>(
      () => GetRouteOverviewUseCase(repository: i.get()),
    );
    i.registerLazySingleton<FlightSearchRepository>(
      () => ApiFlightSearchRepository(
        numberSearchApi: i.get(),
        upcomingSearchApi: i.get(),
        routeSearchApi: i.get(),
        routePreviewApi: i.get(),
        airportsDb: i.get(),
        airlinesDb: i.get(),
      ),
    );
    i.registerLazySingleton<SearchFlightsByNumberUseCase>(
      () => SearchFlightsByNumberUseCase(repository: i.get()),
    );
    i.registerLazySingleton<SearchUpcomingFlightsByNumberUseCase>(
      () => SearchUpcomingFlightsByNumberUseCase(repository: i.get()),
    );
    i.registerLazySingleton<BuildFlightRoutePreviewUseCase>(
      () => BuildFlightRoutePreviewUseCase(repository: i.get()),
    );
    i.registerLazySingleton<SearchFlightsByRouteUseCase>(
      () => SearchFlightsByRouteUseCase(repository: i.get()),
    );
    i.registerLazySingleton<MapboxEnvConfig>(MapboxEnvConfig.fromEnvironment);

    i.registerLazySingleton<MapboxStaticImageApi>(
      () => MapboxStaticImageApi(
        httpClient: i.get(),
        accessToken: i.get<MapboxEnvConfig>().trimmedAccessToken,
      ),
    );
    i.registerLazySingleton<RouteMapImageStore>(
      () => RouteMapImageStore(api: i.get()),
    );
    i.registerLazySingleton<GenerateShareImageUseCase>(
      () => GenerateShareImageUseCase(mapboxApi: i.get(), imageStore: i.get()),
    );
    i.registerLazySingleton<MapboxRasterTileApi>(
      () => MapboxRasterTileApi(
        httpClient: i.get(),
        accessToken: i.get<MapboxEnvConfig>().trimmedAccessToken,
      ),
    );
    i.registerLazySingleton<FlightVideoEncoder>(
      () => FallbackFlightVideoEncoder(
        primary: NativeFlightVideoEncoder(),
        secondary: QuickVideoEncoderAdapter(),
      ),
    );
    i.registerLazySingleton<MediaGallerySaver>(() => const MediaGallerySaver());
    i.registerLazySingleton<GenerateFlightVideoUseCase>(
      () => GenerateFlightVideoUseCase(tileApi: i.get(), encoder: i.get()),
    );

    // Connectivity checker
    i.registerLazySingleton<ConnectivityChecker>(
      () => const ConnectivityChecker(),
    );
    i.registerLazySingleton<NotificationPermissionService>(
      () => NotificationPermissionService(),
    );
    i.registerLazySingleton<ForecastNotificationPrefs>(
      () => ForecastNotificationPrefs(),
    );
    i.registerLazySingleton<FlightWeatherStore>(() => FlightWeatherStore());
    i.registerLazySingleton<FlightNotificationScheduler>(
      () => FlightNotificationScheduler(
        gateway: LocalScheduledNotificationsGateway(),
        timezoneService: i.get<AirportTimezoneService>(),
        permissionService: i.get<NotificationPermissionService>(),
        prefs: i.get<ForecastNotificationPrefs>(),
        flightRepository: i.get<FlightRepository>(),
        subscriptionRepository: i.get<SubscriptionRepository>(),
        analytics: i.get<AppAnalytics>(),
      ),
    );
    i.registerLazySingleton<AppLocationClient>(
      () => GeolocatorAppLocationClient(),
    );
    i.registerLazySingleton<AppLocationService>(
      () => AppLocationService(client: i.get()),
    );
    i.registerFactory<GpsDataProvider>(
      () => GpsDataProvider(locationService: i.get(), unitsRepository: i.get()),
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
    i.registerLazySingleton<NativeReviewRequester>(
      () => DefaultNativeReviewRequester(inAppReview: InAppReview.instance),
    );
    i.registerLazySingleton<AppShareService>(() => DefaultAppShareService());
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
    i.registerLazySingleton<GetWikiArticlesUseCase>(
      () => GetWikiArticlesUseCase(flightInfoApi: GetIt.I.get()),
    );

    i.registerLazySingleton<FlightRepository>(
      () => FlightRepository(service: GetIt.I.get()),
    );
    i.registerLazySingleton<DeleteFlightUseCase>(
      () => DeleteFlightUseCase(service: GetIt.I.get()),
    );
    i.registerLazySingleton<CompleteFlightUseCase>(
      () => CompleteFlightUseCase(service: GetIt.I.get()),
    );
    i.registerLazySingleton<StartFlightUseCase>(
      () => StartFlightUseCase(repository: i.get()),
    );
    i.registerLazySingleton<AutoCompleteStaleInProgressFlightsUseCase>(
      () => AutoCompleteStaleInProgressFlightsUseCase(repository: i.get()),
    );

    i.registerLazySingleton<FavoriteAirportsRepository>(
      () => FavoriteAirportsRepository(),
    );
    i.registerLazySingleton<SettingsRepository>(() => SettingsRepository());
    i.registerLazySingleton<MetricUnitsRepository>(
      () => MetricUnitsRepository(),
    );
    i.registerLazySingleton<VideoAvatarRepository>(
      () => VideoAvatarRepository(),
    );
    i.registerLazySingleton<RecentAirportsRepository>(
      () => RecentAirportsRepository(),
    );
    i.registerLazySingleton<PoiWikiPreviewRepository>(
      () => WikidataWikipediaPreviewRepository(apiClient: i.get()),
    );
    i.registerLazySingleton<GetPlaceInfoUseCase>(
      () => GetPlaceInfoUseCase(repository: i.get()),
    );
    i.registerLazySingleton<DownloadRegionWikiArticlesUseCase>(
      () => DownloadRegionWikiArticlesUseCase(repository: i.get()),
    );

    i.registerLazySingleton<UserFlightPrefsStorage>(
      () => UserFlightPrefsStorage(),
    );
    i.registerLazySingleton<UserFlightPrefsRepository>(
      () => UserFlightPrefsRepository(storage: i.get()),
    );
    i.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepository(prefsStorage: i.get()),
    );
    i.registerLazySingleton<FeatureAnnouncementRepository>(
      () => FeatureAnnouncementRepository(onboarding: i.get()),
    );

    i.registerLazySingleton<LearnPackLocalDb>(() => LearnPackLocalDb());
    i.registerLazySingleton<LearnRepository>(
      () => LocalLearnRepository(localDb: i.get()),
    );
    i.registerLazySingleton<LearnArticleProgressRepository>(
      () => SharedPrefsLearnArticleProgressRepository(),
    );
    i.registerLazySingleton<GeoQuizRepository>(() => AssetGeoQuizRepository());
    i.registerLazySingleton<GeoQuizProgressRepository>(
      () => SharedPrefsGeoQuizProgressRepository(),
    );
    i.registerLazySingleton<SkyCameraMediaRepository>(
      () => SkyCameraMediaRepository(database: i.get()),
    );
    i.registerLazySingleton<FlymapSkyCameraExportService>(
      () => FlymapSkyCameraExportService(
        flightRepository: i.get(),
        mediaRepository: i.get(),
      ),
    );
    i.registerLazySingleton<FlymapSkyCameraShareService>(
      () => FlymapSkyCameraShareService(analytics: i.get()),
    );
    i.registerLazySingleton<SkyCameraVideoRenditionService>(
      () => SkyCameraVideoRenditionService(repository: i.get()),
    );
    i.registerLazySingleton<FlymapSkyCameraSessionFactory>(
      () => FlymapSkyCameraSessionFactory(
        exportService: i.get(),
        shareService: i.get(),
        analytics: i.get(),
        flightRepository: i.get(),
        locationService: i.get(),
      ),
    );
    i.registerFactoryParam<GeoQuizListCubit, String, Object?>(
      (collectionId, _) => GeoQuizListCubit(
        collectionId: collectionId,
        repository: i.get(),
        progressRepository: i.get(),
        analytics: i.get(),
      ),
    );
    i.registerFactoryParam<GeoQuizCubit, GeoQuizSummary, bool>(
      (summary, isProUser) => GeoQuizCubit(
        summary: summary,
        repository: i.get(),
        progressRepository: i.get(),
        languageCodeProvider: () => AppLocalization.currentLanguageCode,
        analytics: i.get(),
        isProUser: isProUser,
        nowProvider: DateTime.now,
      ),
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
    i.registerLazySingleton<RevenueCatIdentityMigrationStore>(
      () => SharedPrefsRevenueCatIdentityMigrationStore(),
    );
    i.registerLazySingleton<FlightUnlockRepository>(
      () => RevenueCatFlightUnlockRepository(client: i.get(), config: i.get()),
    );
    i.registerLazySingleton<SubscriptionRepository>(
      () => RevenueCatSubscriptionRepository(
        client: i.get(),
        config: i.get(),
        statusCache: i.get(),
        identityMigrationStore: i.get(),
        authRepository: i.get(),
        analyticsContextStore: i.get(),
      ),
    );
  }
}
