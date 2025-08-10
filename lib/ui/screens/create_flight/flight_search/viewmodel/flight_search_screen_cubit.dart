import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing flight_search screen state
class FlightSearchScreenCubit extends Cubit<FlightSearchScreenState> {
  FlightSearchScreenCubit({IAirportsDb? airportsDb})
    : _airportsDb = airportsDb ?? AirportsDatabase.instance,
      super(const FlightSearchInitial());

  final IAirportsDb _airportsDb;

  /// Search airports by query (name, city, or code)
  void searchAirports(String query) async {
    if (query.isEmpty) {
      emit(const FlightSearchInitial());
      return;
    }

    emit(const AirportSearchLoading());

    try {
      // Ensure database is initialized
      if (!_airportsDb.isInitialized) {
        await _airportsDb.initialize();
      }

      final results = _airportsDb.search(query);

      if (results.isEmpty) {
        emit(const AirportSearchNoResults());
      } else {
        // Limit results to 10 airports
        final limitedResults = results.take(10).toList();
        emit(AirportSearchResults(airports: limitedResults));
      }
    } catch (e) {
      emit(const AirportSearchNoResults());
    }
  }
}
