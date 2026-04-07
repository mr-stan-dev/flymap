import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_info_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';

class FlightSearchOverviewStep extends StatelessWidget {
  const FlightSearchOverviewStep({
    required this.state,
    required this.isProUser,
    required this.onContinue,
    required this.onUpgradeToPro,
    super.key,
  });

  final FlightPreviewState state;
  final bool isProUser;
  final VoidCallback onContinue;
  final VoidCallback onUpgradeToPro;

  @override
  Widget build(BuildContext context) {
    final route = state.flightRoute;
    if (route == null) {
      return Center(child: Text(context.t.createFlight.overview.routeNotReady));
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                FlightInfoWidget(
                  route: route,
                  info: state.flightInfo,
                  isOverviewLoading: state.isOverviewLoading,
                  overviewErrorMessage: state.isOverviewLoading
                      ? null
                      : state.errorMessage,
                ),
                if (!isProUser)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(DsSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DsBrandColors.proAmber.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t.createFlight.overview.proPoiUpsell,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: DsSpacing.sm),
                          PremiumButton(
                            onPressed: onUpgradeToPro,
                            label: context.t.common.upgrade,
                            icon: Icons.workspace_premium_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: PrimaryButton(
            onPressed: onContinue,
            label: context.t.common.kContinue,
          ),
        ),
      ],
    );
  }
}
