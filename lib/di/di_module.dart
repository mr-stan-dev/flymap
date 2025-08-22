import 'package:flymap/data/api/flight_info_api.dart';
import 'package:flymap/data/api/flight_info_api_mapper.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/flights_local_db_service.dart';
import 'package:flymap/data/local/mappers/flight_db_mapper.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/data/route/great_circle_route_provider.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:get_it/get_it.dart';

class DiModule {
  final i = GetIt.I;

  void register() {
    i.registerLazySingleton<IAirportsDb>(() => AirportsDatabase.instance);

    // Register database
    i.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

    i.registerFactory<FlightInfoApiMapper>(() => FlightInfoApiMapper());

    i.registerFactory<FlightInfoApi>(() => FlightInfoApi(apiMapper: i.get()));

    i.registerFactory<FlightDbMapper>(() => FlightDbMapper());

    i.registerLazySingleton<FlightsLocalDBService>(
      () => FlightsLocalDBService(database: i.get(), flightMapper: i.get()),
    );

    i.registerFactory<FlightRouteProvider>(() => GreatCircleRouteProvider());

    i.registerLazySingleton<DownloadMapUseCase>(
      () => DownloadMapUseCase(service: GetIt.I.get()),
    );
    i.registerLazySingleton<GetFlightInfoUseCase>(
      () => GetFlightInfoUseCase(flightInfoApi: GetIt.I.get()),
    );

    i.registerLazySingleton<FlightRepository>(
      () => FlightRepository(service: GetIt.I.get()),
    );
  }
}
