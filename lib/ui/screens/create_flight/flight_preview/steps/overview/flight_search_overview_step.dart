import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/map_preview/map_detail_hint.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_info_widget.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/usecase/poi_selection_config.dart';

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
    final currentPoiCount = state.flightInfo.poi.length;
    final proPoiCount = state.proPoiCount ?? PoiSelectionConfig.proMaxPois;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                if (!isProUser && state.flightInfo.poi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MapDetailHint(
                          message: context.t.createFlight.mapPreview
                              .proGateHint(count: proPoiCount),
                          details: context.t.createFlight.overview.proPoiUpsell(
                            current: currentPoiCount,
                            total: proPoiCount,
                          ),
                          highlighted: true,
                        ),
                        const SizedBox(height: 12),
                        PremiumButton(
                          onPressed: onUpgradeToPro,
                          label: context.t.common.upgrade,
                          icon: Icons.workspace_premium_rounded,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PrimaryButton(
            onPressed: onContinue,
            label: context.t.common.kContinue,
          ),
        ),
      ],
    );
  }
}
