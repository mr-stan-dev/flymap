import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/analytics/app_analytics_initializer.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/crashlytics/app_crashlytics_initializer.dart';
import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/flights_db_service.dart';
import 'package:flymap/data/local/mappers/flight_db_mapper.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/data/route/great_circle_route_provider.dart';
import 'package:flymap/data/wiki/wikipedia_article_client.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/revenuecat_client.dart';
import 'package:flymap/subscription/revenuecat_env_config.dart';
import 'package:flymap/subscription/subscription_status_cache.dart';
import 'package:flymap/usecase/build_wikipedia_candidates_use_case.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:get_it/get_it.dart';

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

    i.registerLazySingleton<DownloadMapUseCase>(
      () => DownloadMapUseCase(
        service: GetIt.I.get(),
        connectivity: GetIt.I.get(),
      ),
    );
    i.registerLazySingleton<WikipediaArticleClient>(
      () => WikipediaArticleClient(),
    );
    i.registerLazySingleton<BuildWikipediaCandidatesUseCase>(
      () => const BuildWikipediaCandidatesUseCase(),
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

    i.registerLazySingleton<FavoriteAirportsRepository>(
      () => FavoriteAirportsRepository(),
    );

    i.registerLazySingleton<OnboardingRepository>(() => OnboardingRepository());

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
