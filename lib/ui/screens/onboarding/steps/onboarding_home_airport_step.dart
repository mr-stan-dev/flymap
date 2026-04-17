import 'package:flutter/material.dart';
import 'package:flymap/entity/airport.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:flymap/ui/screens/onboarding/widgets/profile/home_airport_selector.dart';

class OnboardingHomeAirportStep extends StatelessWidget {
  const OnboardingHomeAirportStep({
    required this.title,
    required this.subtitle,
    required this.selectedAirport,
    required this.query,
    required this.isSearchLoading,
    required this.results,
    required this.popular,
    required this.onQueryChanged,
    required this.onSelectAirport,
    required this.onClearSelectedAirport,
    this.errorMessage,
    super.key,
  });

  final String title;
  final String subtitle;
  final Airport? selectedAirport;
  final String query;
  final bool isSearchLoading;
  final List<Airport> results;
  final List<Airport> popular;
  final ValueChanged<String> onQueryChanged;
  final Future<void> Function(Airport airport) onSelectAirport;
  final Future<void> Function() onClearSelectedAirport;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: title,
      subtitle: subtitle,
      body: HomeAirportSelector(
        selectedAirport: selectedAirport,
        query: query,
        isSearchLoading: isSearchLoading,
        results: results,
        popular: popular,
        onQueryChanged: onQueryChanged,
        onSelectAirport: onSelectAirport,
        onClearSelectedAirport: onClearSelectedAirport,
        errorMessage: errorMessage,
      ),
    );
  }
}
