import 'package:equatable/equatable.dart';
import 'package:flymap/entity/flight_poi.dart';

class FlightInfo extends Equatable {
  final String overview;
  final List<FlightPoi> poi;
  const FlightInfo(this.overview, this.poi);

  static const FlightInfo empty = FlightInfo('', <FlightPoi>[]);
  bool get isEmpty => overview.isEmpty && poi.isEmpty;

  @override
  List<Object?> get props => [overview, poi.length];
}
