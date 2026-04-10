import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/info/route_copy_builder.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';

class FlightAppBar extends StatelessWidget {
  const FlightAppBar({required this.flight, this.hideProgress = 0, super.key});

  // TODO: Re-enable share route menu item after we fix android snapshot
  static const bool _shareRouteMenuEnabled = false;

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

  final Flight flight;
  final double hideProgress; // 0..1 where 1 = fully hidden (pushed up)

  @override
  Widget build(BuildContext context) {
    final isProUser = context.select(
      (SubscriptionCubit cubit) => cubit.state.isPro,
    );
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  if (isProUser)
                    const Positioned(
                      left: 0,
                      top: 0,
                      right: 0,
                      child: ProGradientStrip(height: 3),
                    ),
                  Padding(
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
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${flight.route.departure.displayCode}-${flight.route.arrival.displayCode}',
                                  style: context.textTheme.button18Bold,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isProUser) ...[
                                const SizedBox(width: 8),
                                const ProBadge(compact: true),
                              ],
                            ],
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
                              await _handleMenuAction(context, value);
                            },
                            itemBuilder: (context) => [
                              if (_shareRouteMenuEnabled)
                                PopupMenuItem(
                                  value: 'share_route',
                                  child: Text(context.t.flight.shareRoute),
                                ),
                              PopupMenuItem(
                                value: 'copy_route',
                                child: Text(context.t.flight.copyRoute),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete_flight',
                                child: Text(context.t.flight.deleteFlight),
                              ),
                            ],
                          ),
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

  Future<void> _handleMenuAction(BuildContext context, String value) async {
    switch (value) {
      case 'share_route':
        AppRouter.goToShareFlight(context, flight: flight);
        break;
      case 'copy_route':
        final routeSummary = RouteCopyBuilder.build(flight.route);
        await Clipboard.setData(ClipboardData(text: routeSummary));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.flight.routeSummaryCopied)),
          );
        }
        break;
      case 'delete_flight':
        final confirmed = await DeleteFlightConfirmationDialog.show(
          context,
          reclaimedBytes: _mapSizeBytes(),
        );
        if (confirmed != true || !context.mounted) return;
        await context.read<FlightScreenCubit>().deleteFlight();
        break;
    }
  }

  int _mapSizeBytes() {
    if (flight.maps.isEmpty) return 0;
    return flight.maps.fold<int>(0, (sum, map) => sum + map.sizeBytes);
  }
}
