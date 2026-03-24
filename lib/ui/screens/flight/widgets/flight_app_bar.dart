import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight_route.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';

class FlightAppBar extends StatelessWidget {
  const FlightAppBar({required this.route, this.hideProgress = 0, super.key});

  static const double _outerPadding = 16;
  static const double _innerPadding = 8;
  static const double _buttonSize = 48;

  /// Total occupied height when rendered at the top of screen, including
  /// status-bar inset and internal paddings.
  static double totalOverlayHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top +
        (_outerPadding * 2) +
        (_innerPadding * 2) +
        _buttonSize;
  }

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
          padding: const EdgeInsets.all(_outerPadding),
          child: Container(
            decoration: BoxDecoration(
              color: context.colorTheme.backgroundPrimary.withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_innerPadding),
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
                    child: Text(
                      '${route.departure.displayCode}-${route.arrival.displayCode}',
                      style: context.textTheme.button18Bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: context.colorTheme.backgroundPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        switch (value) {
                          case 'delete_flight':
                            await context
                                .read<FlightScreenCubit>()
                                .deleteFlight();
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'delete_flight',
                          child: Text('Delete flight'),
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
