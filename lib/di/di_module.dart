import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/data/local/app_database.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:get_it/get_it.dart';

class DiModule {
  final i = GetIt.I;

  void register() {
    i.registerLazySingleton<IAirportsDb>(() => AirportsDatabase.instance);

    // Register database
    i.registerLazySingleton<AppDatabase>(() => AppDatabase.instance);

    i.registerLazySingleton<DownloadMapUseCase>(
      () => DownloadMapUseCase(
        database: GetIt.I.get(),
      ),
    );

    i.registerLazySingleton<FlightRepository>(
      () => FlightRepository(database: GetIt.I.get()),
    );
  }
}
