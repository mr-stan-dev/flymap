import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/create_flight/download_completed/download_completed_args.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';

class DownloadCompletedRouteScreen extends StatefulWidget {
  const DownloadCompletedRouteScreen({required this.args, super.key});

  final DownloadCompletedArgs args;

  @override
  State<DownloadCompletedRouteScreen> createState() =>
      _DownloadCompletedRouteScreenState();
}

class _DownloadCompletedRouteScreenState
    extends State<DownloadCompletedRouteScreen> {
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
          onHomePressed: () => unawaited(_onHomePressed()),
          onSharePressed: () => _onSharePressed(widget.args.flightId),
          onShareVideoPressed: () => _onShareVideoPressed(widget.args.flightId),
        ),
      ),
    );
  }

  void _onSharePressed(String flightId) {
    unawaited(_openShareFromHomeStack(flightId));
  }

  void _onShareVideoPressed(String flightId) {
    unawaited(_openVideoFromHomeStack(flightId));
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
    homeRefreshNotifier.value = true;
    AppRouter.goHome(context);
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
    required this.onHomePressed,
    required this.onSharePressed,
    required this.onShareVideoPressed,
    super.key,
  });

  final VoidCallback onHomePressed;
  final VoidCallback onSharePressed;
  final VoidCallback onShareVideoPressed;

  @override
  Widget build(BuildContext context) {
    return FlightDownloadCompletion(
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
