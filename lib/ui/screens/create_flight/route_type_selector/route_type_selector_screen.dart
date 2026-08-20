import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_unlock_gate_sheet.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';
import 'widgets/route_type_card.dart';

enum RouteType { basic, pro }

class FlightRouteTypeSelector extends StatefulWidget {
  const FlightRouteTypeSelector({this.entrySource = 'unknown', super.key});

  final String entrySource;

  @override
  State<FlightRouteTypeSelector> createState() =>
      _FlightRouteTypeSelectorState();
}

class _FlightRouteTypeSelectorState extends State<FlightRouteTypeSelector> {
  RouteType _selectedType = RouteType.basic;
  bool _hasPendingFlightUnlock = false;
  final AppAnalytics _analytics = GetIt.I.get<AppAnalytics>();
  final String _creationAttemptId = const Uuid().v4();
  final Set<RouteType> _loggedCardTaps = <RouteType>{};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, subState) {
        final navigator = Navigator.of(context);
        final canPop = navigator.canPop();
        final isPro = subState.isPro;
        final hasUnlockedProRoute = isPro || _hasPendingFlightUnlock;
        final t = context.t.createFlight.routeTypeSelector;

        return PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBackNavigation(context, canPop: canPop);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackNavigation(context, canPop: canPop),
              ),
              title: Text(t.title),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DsSpacing.xl),
                child: Column(
                  children: [
                    RouteTypeCard(
                      type: RouteType.basic,
                      title: t.basicTitle,
                      subtitle: t.basicSubtitle,
                      description: t.basicDescription,
                      isSelected: _selectedType == RouteType.basic,
                      onTap: () =>
                          _selectRouteType(RouteType.basic, isProUser: isPro),
                    ),
                    const SizedBox(height: DsSpacing.md),
                    RouteTypeCard(
                      type: RouteType.pro,
                      title: t.proTitle,
                      subtitle: t.proSubtitle,
                      description: t.proDescription,
                      isSelected: _selectedType == RouteType.pro,
                      isProOnly: true,
                      onTap: () =>
                          _selectRouteType(RouteType.pro, isProUser: isPro),
                    ),
                    const Spacer(),
                    if (_selectedType == RouteType.pro && !hasUnlockedProRoute)
                      PremiumButton(
                        label: context.t.common.upgrade,
                        onPressed: () => _handleUnlockRealRoute(
                          context,
                          subscriptionCubit: context.read<SubscriptionCubit>(),
                        ),
                      )
                    else
                      PrimaryButton(
                        label: context.t.common.kContinue,
                        onPressed: () {
                          _logRouteTypeSelected(
                            isProUser: isPro,
                            hasPendingFlightUnlock: _hasPendingFlightUnlock,
                          );
                          if (_selectedType == RouteType.basic) {
                            AppRouter.goToFlightSearch(context);
                          } else {
                            AppRouter.goToFlightNumberSelector(
                              context,
                              hasPendingFlightUnlock: _hasPendingFlightUnlock,
                            );
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _logRouteTypeSelected({
    required bool isProUser,
    required bool hasPendingFlightUnlock,
  }) {
    unawaited(
      _analytics.log(
        RouteTypeSelectedEvent(
          routeType: _selectedType == RouteType.basic
              ? SelectedRouteType.airports
              : SelectedRouteType.realRoute,
          isProUser: isProUser,
          hasPendingFlightUnlock: hasPendingFlightUnlock,
          entrySource: widget.entrySource,
          creationAttemptId: _creationAttemptId,
        ),
      ),
    );
  }

  void _selectRouteType(RouteType routeType, {required bool isProUser}) {
    if (_loggedCardTaps.add(routeType)) {
      unawaited(
        _analytics.log(
          RouteTypeCardTappedEvent(
            routeType: routeType == RouteType.basic
                ? RouteTypeCardType.basic
                : RouteTypeCardType.realRoute,
            accessState: isProUser
                ? RouteTypeAccessState.pro
                : _hasPendingFlightUnlock
                ? RouteTypeAccessState.singleFlightUnlock
                : RouteTypeAccessState.free,
            entrySource: widget.entrySource,
            creationAttemptId: _creationAttemptId,
          ),
        ),
      );
    }
    if (_selectedType == routeType) return;
    setState(() => _selectedType = routeType);
  }

  void _handleBackNavigation(BuildContext context, {required bool canPop}) {
    if (canPop) {
      Navigator.of(context).pop();
      return;
    }
    AppRouter.goHome(context);
  }

  Future<void> _handleUnlockRealRoute(
    BuildContext context, {
    required SubscriptionCubit subscriptionCubit,
  }) async {
    await showFlightUnlockGateSheet(
      context: context,
      subscriptionCubit: subscriptionCubit,
      source: PaywallSource.realRouteGate,
      creationAttemptId: _creationAttemptId,
      presentProPaywall: () =>
          subscriptionCubit.presentPaywallFromRealRouteGate(
            creationAttemptId: _creationAttemptId,
          ),
      onUnlockActivated: () async {
        if (!mounted) return;
        setState(() {
          _hasPendingFlightUnlock = true;
        });
      },
    );
  }
}
