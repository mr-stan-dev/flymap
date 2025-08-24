import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';

class FlightSearchScreenCubit extends Cubit<FlightSearchScreenState> {
  FlightSearchScreenCubit({required AirportsDatabase airportsDb})
    : _airportsDb = airportsDb,
      super(const FlightSearchInitial());

  final AirportsDatabase _airportsDb;

  /// Search airports by query (name, city, or code)
  void searchAirports(String query) async {
    if (query.isEmpty) {
      emit(const FlightSearchInitial());
      return;
    }

    emit(const AirportSearchLoading());

    try {
      await _airportsDb.initialize();

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
