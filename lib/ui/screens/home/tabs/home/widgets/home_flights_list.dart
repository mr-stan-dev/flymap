import 'package:flutter/material.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/domain/entity/units.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flight_card.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flights_empty_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flights_section_header.dart';

class HomeFlightsList extends StatelessWidget {
  const HomeFlightsList({
    required this.flights,
    required this.hasCompletedFlights,
    required this.onViewAll,
    required this.onAddFirstFlight,
    required this.distanceUnit,
    super.key,
  });

  final List<Flight> flights;
  final bool hasCompletedFlights;
  final VoidCallback onViewAll;
  final VoidCallback onAddFirstFlight;
  final DistanceUnit distanceUnit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeFlightsSectionHeader(count: flights.length, onViewAll: onViewAll),
        const SizedBox(height: 12),
        _buildFlightsContent(),
      ],
    );
  }

  Widget _buildFlightsContent() {
    if (flights.isEmpty) {
      return HomeFlightsEmptyState(
        onAddFirstFlight: onAddFirstFlight,
        hasCompletedFlights: hasCompletedFlights,
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flights.length,
      itemBuilder: (context, index) {
        final flight = flights[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < flights.length - 1 ? 12 : 0),
          child: HomeFlightCard(flight: flight, distanceUnit: distanceUnit),
        );
      },
    );
  }
}
