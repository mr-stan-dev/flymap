import 'package:flutter/material.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class FlightPreviewAppBar extends StatelessWidget {
  const FlightPreviewAppBar({
    required this.route,
    this.hideProgress = 0,
    super.key,
  });
  final FlightRoute route;
  final double hideProgress; // 0..1 where 1 = fully hidden (pushed up)

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        // Slide a bit more than full height to fully hide any residual edge
        offset: Offset(0, -1.1 * hideProgress),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: context.colorTheme.backgroundPrimary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${route.departure.displayCode}-${route.arrival.displayCode}',
                          style: context.textTheme.button18Bold,
                        ),
                        Text(
                          '${route.departure.cityWithCountryCode}-${route.arrival.cityWithCountryCode}',
                          style: context.textTheme.body16Regular,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
