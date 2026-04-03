import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/flight_search_by_airports.dart';
import 'package:flymap/usecase/build_wikipedia_candidates_use_case.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:get_it/get_it.dart';

class FlightSearchScreen extends StatelessWidget {
  const FlightSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FlightSearchScreenCubit(
        airportsDb: GetIt.I.get(),
        favoritesRepository: GetIt.I.get<FavoriteAirportsRepository>(),
        routeProvider: GetIt.I.get<FlightRouteProvider>(),
        downloadMapUseCase: GetIt.I.get<DownloadMapUseCase>(),
        buildWikipediaCandidatesUseCase: GetIt.I
            .get<BuildWikipediaCandidatesUseCase>(),
        downloadWikipediaArticlesUseCase: GetIt.I
            .get<DownloadWikipediaArticlesUseCase>(),
        getFlightInfoUseCase: GetIt.I.get<GetFlightInfoUseCase>(),
        analytics: GetIt.I.get<AppAnalytics>(),
        crashlytics: GetIt.I.get<AppCrashlytics>(),
      ),
      child: const FlightSearchByAirports(),
    );
  }
}
