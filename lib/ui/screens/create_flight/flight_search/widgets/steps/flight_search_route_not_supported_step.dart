import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/info/flight_info_widget.dart';

class FlightSearchRouteNotSupportedStep extends StatelessWidget {
  const FlightSearchRouteNotSupportedStep({
    required this.route,
    required this.message,
    required this.onBack,
    super.key,
  });

  final FlightRoute route;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DsSpacing.md),
            child: Column(
              children: [
                FlightInfoWidget(route: route, info: FlightInfo.empty),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DsSpacing.lg),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(DsSpacing.md),
          child: SecondaryButton(
            label: context.t.common.back,
            leadingIcon: Icons.arrow_back_rounded,
            onPressed: onBack,
          ),
        ),
      ],
    );
  }
}
