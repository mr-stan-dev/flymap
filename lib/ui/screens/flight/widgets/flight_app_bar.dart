import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/domain/entity/flight.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/flight/viewmodel/flight_screen_cubit.dart';
import 'package:flymap/ui/screens/flight/widgets/complete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/flight/widgets/delete_flight_confirmation_dialog.dart';
import 'package:flymap/ui/screens/flight/widgets/tabs/debug/flight_debug_screen.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/theme/app_theme_ext.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:flymap/utils/route_utils.dart';

class FlightAppBar extends StatelessWidget {
  const FlightAppBar({required this.flight, super.key});

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

  @override
  Widget build(BuildContext context) {
    final showProStyling = flight.hasProAccess;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.all(_outerPadding),
        child: Container(
          decoration: BoxDecoration(
            color: context.colorTheme.backgroundPrimary.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                if (showProStyling)
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    RouteUtils.routeCities(flight.route),
                                    style: context.textTheme.button18Bold,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              RouteUtils.routeCountries(context, flight.route),
                              style: context.textTheme.caption14Regular
                                  .copyWith(
                                    color: context.colorTheme.textSecondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
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
                            PopupMenuItem(
                              value: 'share_route',
                              child: Text(context.t.flight.shareRoute),
                            ),
                            if (kDebugMode)
                              PopupMenuItem(
                                key: const Key('flight.debug_menu_item'),
                                value: 'debug',
                                child: Text(context.t.common.debug),
                              ),
                            PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'complete_flight',
                              child: Text(context.t.home.completeFlight),
                            ),
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
    );
  }

  Future<void> _handleMenuAction(BuildContext context, String value) async {
    switch (value) {
      case 'share_route':
        AppRouter.goToShareImage(context, flightId: flight.id);
        break;
      case 'debug':
        if (!kDebugMode) return;
        final cubit = context.read<FlightScreenCubit>();
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const FlightDebugScreen(),
            ),
          ),
        );
        break;
      case 'delete_flight':
        final confirmed = await DeleteFlightConfirmationDialog.show(
          context,
          reclaimedBytes: _mapSizeBytes(),
        );
        if (confirmed != true || !context.mounted) return;
        await context.read<FlightScreenCubit>().deleteFlight();
        break;
      case 'complete_flight':
        final result = await CompleteFlightConfirmationDialog.show(context);
        if (result == null || !context.mounted) return;
        final completed = await context
            .read<FlightScreenCubit>()
            .completeFlight(deleteOfflineData: result.deleteOfflineData);
        if (!completed || !context.mounted) return;
        homeRefreshNotifier.value = true;
        AppRouter.goHome(context);
        break;
    }
  }

  int _mapSizeBytes() {
    if (flight.maps.isEmpty) return 0;
    return flight.maps.fold<int>(0, (sum, map) => sum + map.sizeBytes);
  }
}
