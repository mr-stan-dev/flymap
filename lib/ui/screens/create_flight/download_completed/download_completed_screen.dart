import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/download_completed/download_completed_args.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:get_it/get_it.dart';

class DownloadCompletedRouteScreen extends StatefulWidget {
  const DownloadCompletedRouteScreen({required this.args, super.key});

  final DownloadCompletedArgs args;

  @override
  State<DownloadCompletedRouteScreen> createState() =>
      _DownloadCompletedRouteScreenState();
}

class _DownloadCompletedRouteScreenState
    extends State<DownloadCompletedRouteScreen> {
  final AppAnalytics _analytics = GetIt.I.get<AppAnalytics>();
  final FlightRepository _flightRepository = GetIt.I.get<FlightRepository>();
  final Set<DownloadCompletedAction> _loggedActions =
      <DownloadCompletedAction>{};

  @override
  Widget build(BuildContext context) {
    final proAccessInfo = _proAccessInfo(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onHomePressed();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t.preview.downloadCompletedTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => unawaited(_onHomePressed()),
          ),
          actions: proAccessInfo == null
              ? null
              : [
                  ProAppBarInfoButton(
                    title: proAccessInfo.title,
                    message: proAccessInfo.message,
                    tooltip: context.t.createFlight.proAccess.tooltip,
                  ),
                ],
        ),
        body: DownloadCompletedScreen(
          onOpenFlightPressed: () => unawaited(_onOpenFlightPressed()),
          onHomePressed: () => unawaited(_onHomePressed()),
          onSharePressed: () => _onSharePressed(widget.args.flightId),
          onShareVideoPressed: () => _onShareVideoPressed(widget.args.flightId),
        ),
      ),
    );
  }

  void _onSharePressed(String flightId) {
    _logAction(DownloadCompletedAction.share);
    unawaited(_openShareFromHomeStack(flightId));
  }

  void _onShareVideoPressed(String flightId) {
    _logAction(DownloadCompletedAction.shareVideo);
    unawaited(_openVideoFromHomeStack(flightId));
  }

  Future<void> _onOpenFlightPressed() async {
    _logAction(DownloadCompletedAction.openFlight);
    try {
      final flight = await _flightRepository.getFlightById(
        widget.args.flightId,
      );
      if (!mounted) return;
      if (flight == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.preview.errorSomethingWrong)),
        );
        return;
      }
      homeRefreshNotifier.value = true;
      await AppRouter.goToFlightFromHomeStack(context, flight: flight);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.preview.errorSomethingWrong)),
      );
    }
  }

  Future<void> _openShareFromHomeStack(String flightId) async {
    if (!mounted) return;
    homeRefreshNotifier.value = true;
    AppRouter.goHome(context);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    AppRouter.goToShareImage(context, flightId: flightId);
  }

  Future<void> _openVideoFromHomeStack(String flightId) async {
    if (!mounted) return;
    homeRefreshNotifier.value = true;
    AppRouter.goHome(context);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    AppRouter.goToFlightVideo(context, flightId: flightId);
  }

  Future<void> _onHomePressed() async {
    _logAction(DownloadCompletedAction.home);
    homeRefreshNotifier.value = true;
    AppRouter.goHome(context);
  }

  void _logAction(DownloadCompletedAction action) {
    if (!_loggedActions.add(action)) return;
    unawaited(
      _analytics.log(
        DownloadCompletedActionEvent(
          action: action,
          accessMode: widget.args.isProSubscriber
              ? 'pro'
              : widget.args.usedSingleFlightUnlock
              ? 'single_flight_unlock'
              : 'basic',
          creationAttemptId: widget.args.creationAttemptId,
        ),
      ),
    );
  }

  _ProAccessInfo? _proAccessInfo(BuildContext context) {
    if (widget.args.isProSubscriber) {
      return _ProAccessInfo(
        title: context.t.createFlight.proAccess.subscriber,
        message: context.t.createFlight.proAccess.subscriberBody,
      );
    }
    if (widget.args.usedSingleFlightUnlock) {
      return _ProAccessInfo(
        title: context.t.createFlight.proAccess.unlockedFlight,
        message: context.t.createFlight.proAccess.unlockedFlightBody,
      );
    }
    return null;
  }
}

class DownloadCompletedScreen extends StatelessWidget {
  const DownloadCompletedScreen({
    required this.onOpenFlightPressed,
    required this.onHomePressed,
    required this.onSharePressed,
    required this.onShareVideoPressed,
    super.key,
  });

  final VoidCallback onOpenFlightPressed;
  final VoidCallback onHomePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onShareVideoPressed;

  @override
  Widget build(BuildContext context) {
    return FlightDownloadCompletion(
      onOpenFlightPressed: onOpenFlightPressed,
      onHomePressed: onHomePressed,
      onSharePressed: onSharePressed,
      onShareVideoPressed: onShareVideoPressed,
    );
  }
}

class _ProAccessInfo {
  const _ProAccessInfo({required this.title, required this.message});

  final String title;
  final String message;
}
