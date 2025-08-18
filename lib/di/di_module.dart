import 'package:flymap/data/api/get_poi_api.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/data/local/flight_info_mapper.dart';
import 'package:flymap/data/local/flights_local_db_service.dart';
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

    i.registerLazySingleton<GetPoiApi>(() => GetPoiApi());

    i.registerLazySingleton<FlightInfoMapper>(() => FlightInfoMapper());

    i.registerLazySingleton<FlightsLocalDBService>(
      () => FlightsLocalDBService(database: i.get(), flightInfoMapper: i.get()),
    );

    i.registerLazySingleton<DownloadMapUseCase>(
      () => DownloadMapUseCase(service: GetIt.I.get()),
    );
    i.registerLazySingleton<GetFlightInfoUseCase>(
      () => GetFlightInfoUseCase(getPoiApi: GetIt.I.get()),
    );

    i.registerLazySingleton<FlightRepository>(
      () => FlightRepository(service: GetIt.I.get()),
    );
  }
}
