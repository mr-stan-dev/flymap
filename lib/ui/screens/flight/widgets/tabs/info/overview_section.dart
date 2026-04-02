import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/shared/flight_overview_content.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/section_card.dart';

class OverviewSection extends StatelessWidget {
  const OverviewSection({
    required this.overview,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final String overview;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return InfoSectionCard(
      title: context.t.flight.info.overviewTitle,
      child: FlightOverviewContent(
        overview: overview,
        isLoading: isLoading,
        errorMessage: errorMessage,
        loadingMessage: context.t.flight.info.overviewLoading,
        emptyMessage: context.t.flight.info.overviewEmpty,
      ),
    );
  }
}
