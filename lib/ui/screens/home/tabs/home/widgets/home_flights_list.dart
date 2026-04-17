import 'package:flutter/material.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flight_card.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flights_empty_state.dart';
import 'package:flymap/ui/screens/home/tabs/home/widgets/flights_list/home_flights_section_header.dart';

class HomeFlightsList extends StatelessWidget {
  const HomeFlightsList({
    required this.flights,
    required this.selectedSort,
    required this.onSortChanged,
    required this.onAddFirstFlight,
    super.key,
  });

  final List<Flight> flights;
  final HomeFlightsSort selectedSort;
  final Future<void> Function(HomeFlightsSort sort) onSortChanged;
  final VoidCallback onAddFirstFlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeFlightsSectionHeader(
          count: flights.length,
          selectedSort: selectedSort,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: 12),
        _buildFlightsContent(),
      ],
    );
  }

  Widget _buildFlightsContent() {
    if (flights.isEmpty) {
      return HomeFlightsEmptyState(onAddFirstFlight: onAddFirstFlight);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: flights.length,
      itemBuilder: (context, index) {
        final flight = flights[index];
        return Padding(
          padding: EdgeInsets.only(bottom: index < flights.length - 1 ? 12 : 0),
          child: HomeFlightCard(flight: flight),
        );
      },
    );
  }
}
