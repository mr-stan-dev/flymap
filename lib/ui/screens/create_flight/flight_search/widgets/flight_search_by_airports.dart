import 'package:flymap/entity/airport.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_params.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/popular_flights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../viewmodel/flight_search_screen_cubit.dart';
import '../viewmodel/flight_search_screen_state.dart';
import 'airport_autocomplete_field.dart';

class FlightSearchByAirports extends StatefulWidget {
  final Function(Airport departure, Airport arrival)? onAirportsSelected;

  const FlightSearchByAirports({super.key, this.onAirportsSelected});

  @override
  State<FlightSearchByAirports> createState() => _FlightSearchByAirportsState();
}

class _FlightSearchByAirportsState extends State<FlightSearchByAirports> {
  Airport? _selectedDeparture;
  Airport? _selectedArrival;

  // Controllers for the text fields
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  void dispose() {
    _departureController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Search by Airports')),
      body: SafeArea(
        child: BlocConsumer<FlightSearchScreenCubit, FlightSearchScreenState>(
          listener: (context, state) {
            if (state is FlightSearchError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title
                          const SizedBox(height: 20),
                          Text(
                            'Ready for the next flight?',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Departure airport field
                          AirportAutocompleteField(
                            label: 'Departure Airport',
                            hint: 'Enter departure airport',
                            icon: Icons.flight_takeoff,
                            cubit: context.read<FlightSearchScreenCubit>(),
                            onAirportSelected: (airport) {
                              setState(() {
                                _selectedDeparture = airport;
                              });
                            },
                            onAirportClear: () {
                              setState(() {
                                _selectedDeparture = null;
                              });
                            },
                          ),
                          const SizedBox(height: 20),

                          // Arrival airport field
                          AirportAutocompleteField(
                            label: 'Arrival Airport',
                            hint: 'Enter arrival airport',
                            icon: Icons.flight_land,
                            cubit: context.read<FlightSearchScreenCubit>(),
                            onAirportSelected: (airport) {
                              setState(() {
                                _selectedArrival = airport;
                              });
                            },
                            onAirportClear: () {
                              setState(() {
                                _selectedArrival = null;
                              });
                            },
                          ),
                          const SizedBox(height: 30),
                          _buildSampleFlightsChips(),

                          const SizedBox(height: 20),

                          // Search results or status
                          _buildSearchResults(state),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Fixed search button at bottom
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _bothAirportsSelected()
                          ? () {
                              AppRouter.goToFlightPreviewScreen(
                                context,
                                params: FlightPreviewAirports(
                                  departure: _selectedDeparture!,
                                  arrival: _selectedArrival!,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _buildSearchButtonContent(state),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSampleFlightsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Popular Routes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 4,
          children: popularFlights.map((pair) {
            final departure = pair['departure'] as Airport;
            final arrival = pair['arrival'] as Airport;
            return ActionChip(
              avatar: Icon(
                Icons.flight,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              label: Text(
                '${departure.city} (${departure.code}) → ${arrival.city} (${arrival.code})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.3),
              ),
              onPressed: () => _fillTextFieldsAndContinue(departure, arrival),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _fillTextFieldsAndContinue(Airport departure, Airport arrival) {
    // Fill the text fields with the airports
    _departureController.text = '${departure.name} (${departure.code})';
    _arrivalController.text = '${arrival.name} (${arrival.code})';

    // Update selected airports
    setState(() {
      _selectedDeparture = departure;
      _selectedArrival = arrival;
    });

    // Trigger the continue button action
    AppRouter.goToFlightPreviewScreen(
      context,
      params: FlightPreviewAirports(departure: departure, arrival: arrival),
    );
  }

  Widget _buildSearchResults(FlightSearchScreenState state) {
    if (state is FlightSearchByAirportsLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Searching for flights...'),
          ],
        ),
      );
    }

    if (state is FlightSearchByAirportsResults) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${state.flights.length} flights',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'From ${state.departure.code} to ${state.arrival.code}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      );
    }

    if (state is FlightSearchByAirportsNoResults) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No flights found for this route',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSearchButtonContent(FlightSearchScreenState state) {
    if (state is FlightSearchByAirportsLoading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Searching...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return const Text(
      'Search Flights',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  bool _bothAirportsSelected() {
    return _selectedDeparture != null && _selectedArrival != null;
  }
}
