import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/usecase/build_flight_route_preview_use_case.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/user_flight_prefs_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/subscription/pro_limits.dart';
import 'package:flymap/subscription/paywall_source.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/route_upgrade_choice_sheet.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_args.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_unlock_gate_sheet.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/downloading/flight_search_downloading_view.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/flight_search_route_overview_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/route_not_supported/flight_search_route_not_supported_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/wikipedia_articles/flight_search_wikipedia_articles_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:flymap/domain/usecase/download_map_use_case.dart';
import 'package:flymap/domain/usecase/download_region_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/domain/usecase/get_route_overview_use_case.dart';
import 'package:flymap/domain/usecase/get_wiki_articles_use_case.dart';
import 'package:flymap/domain/usecase/delete_flight_use_case.dart';
import 'package:get_it/get_it.dart';

class FlightPreviewScreen extends StatelessWidget {
  const FlightPreviewScreen({required this.args, super.key});

  final FlightPreviewArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FlightPreviewCubit>(
      create: (_) => FlightPreviewCubit(
        departure: args.departure,
        arrival: args.arrival,
        flightNumber: args.flightNumber,
        fr24Id: args.fr24Id,
        hasPendingFlightUnlock: args.hasPendingFlightUnlock,
        connectivityChecker: GetIt.I.get<ConnectivityChecker>(),
        getRouteOverviewUseCase: GetIt.I.get<GetRouteOverviewUseCase>(),
        buildFlightRoutePreviewUseCase: GetIt.I
            .get<BuildFlightRoutePreviewUseCase>(),
        downloadMapUseCase: GetIt.I.get<DownloadMapUseCase>(),
        downloadRegionWikiArticlesUseCase: GetIt.I
            .get<DownloadRegionWikiArticlesUseCase>(),
        downloadWikipediaArticlesUseCase: GetIt.I
            .get<DownloadWikipediaArticlesUseCase>(),
        getWikiArticlesUseCase: GetIt.I.get<GetWikiArticlesUseCase>(),
        userFlightPrefsRepository: GetIt.I.get<UserFlightPrefsRepository>(),
        flightRepository: GetIt.I.get<FlightRepository>(),
        subscriptionRepository: GetIt.I.get<SubscriptionRepository>(),
        flightUnlockRepository: GetIt.I.get<FlightUnlockRepository>(),
        deleteFlightUseCase: GetIt.I.get<DeleteFlightUseCase>(),
        analytics: GetIt.I.get<AppAnalytics>(),
        crashlytics: GetIt.I.get<AppCrashlytics>(),
      ),
      child: const _FlightPreviewBody(),
    );
  }
}

class _FlightPreviewBody extends StatefulWidget {
  const _FlightPreviewBody();

  @override
  State<_FlightPreviewBody> createState() => _FlightPreviewBodyState();
}

class _FlightPreviewBodyState extends State<_FlightPreviewBody> {
  int _previousStepIndex = 0;
  double _stepEnterFrom = 0.0;
  bool _downloadCompletionHandled = false;
  bool _isShowingOverviewWarning = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlightPreviewCubit, FlightPreviewState>(
      listenWhen: (previous, current) {
        return previous.errorMessage != current.errorMessage ||
            previous.downloadErrorMessage != current.downloadErrorMessage ||
            previous.downloadDone != current.downloadDone ||
            previous.overviewWarningTitle != current.overviewWarningTitle ||
            previous.overviewWarningMessage != current.overviewWarningMessage ||
            previous.step != current.step;
      },
      listener: (listenerContext, state) {
        final nextStepIndex = _stepIndex(state.step);
        if (nextStepIndex != _previousStepIndex) {
          setState(() {
            _stepEnterFrom = nextStepIndex > _previousStepIndex ? 1.0 : -1.0;
            _previousStepIndex = nextStepIndex;
          });
        }

        if (state.errorMessage != null &&
            state.errorMessage!.isNotEmpty &&
            state.step != CreateFlightStep.routeNotSupported) {
          ScaffoldMessenger.of(
            listenerContext,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.downloadErrorMessage != null &&
            state.downloadErrorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(
            listenerContext,
          ).showSnackBar(SnackBar(content: Text(state.downloadErrorMessage!)));
        }

        if (state.downloadDone && !_downloadCompletionHandled) {
          _downloadCompletionHandled = true;
          _handleDownloadCompleted(state);
        }

        final warningTitle = state.overviewWarningTitle;
        final warningMessage = state.overviewWarningMessage;
        if (!_isShowingOverviewWarning &&
            state.step == CreateFlightStep.overview &&
            warningTitle != null &&
            warningTitle.isNotEmpty &&
            warningMessage != null &&
            warningMessage.isNotEmpty) {
          _isShowingOverviewWarning = true;
          unawaited(
            _showOverviewWarningDialog(
              listenerContext,
              title: warningTitle,
              message: warningMessage,
            ),
          );
        }
      },
      builder: (context, state) {
        final isProSubscriber = context.select(
          (SubscriptionCubit cubit) => cubit.state.isPro,
        );
        final isProUser = isProSubscriber || state.hasPendingFlightUnlock;
        final proAccessInfo = _proAccessInfo(
          context,
          isProSubscriber: isProSubscriber,
          hasPendingFlightUnlock: state.hasPendingFlightUnlock,
        );
        final cubit = context.read<FlightPreviewCubit>();
        final subscriptionCubit = context.read<SubscriptionCubit>();

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final shouldPop = await cubit.handleBackAction();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _onBackPressed(context),
              ),
              title: Text(_titleForState(context, state)),
              actions: _buildAppBarActions(
                context,
                state: state,
                proAccessInfo: proAccessInfo,
              ),
            ),
            body: SafeArea(
              top: false,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(state.step.name),
                tween: Tween<double>(begin: _stepEnterFrom, end: 0),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(value * MediaQuery.sizeOf(context).width, 0),
                    child: child,
                  );
                },
                child: _buildContent(
                  context: context,
                  state: state,
                  isProUser: isProUser,
                  cubit: cubit,
                  subscriptionCubit: subscriptionCubit,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required FlightPreviewState state,
    required bool isProUser,
    required FlightPreviewCubit cubit,
    required SubscriptionCubit subscriptionCubit,
  }) {
    if (state.isDownloading) {
      return FlightSearchDownloadingView(
        state: state,
        onCancel: cubit.cancelDownload,
      );
    }

    switch (state.step) {
      case CreateFlightStep.routeNotSupported:
        final route = state.flightRoute;
        if (route == null) {
          return Center(
            child: Text(context.t.createFlight.overview.routeNotReady),
          );
        }
        return FlightSearchRouteNotSupportedStep(
          route: route,
          message:
              state.errorMessage ??
              context.t.createFlight.mapPreview.routeNotSupportedMsg,
          onBack: () => unawaited(_onBackPressed(context)),
        );
      case CreateFlightStep.overview:
        if (state.isPreviewLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  context.t.flight.info.overviewLoading,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        if (!state.hasInternetForMapPreview) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.t.createFlight.errors.noInternet,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }
        return FlightSearchRouteOverviewStep(
          state: state,
          isProUser: isProUser,
          onContinueFromOverview: (isSkipped) => cubit.continueFromOverview(
            isSkipped: isSkipped,
            isProUser: isProUser,
          ),
          onPremiumGateTap: () => unawaited(
            _handleUpgradeToProFromOverview(
              context: context,
              cubit: cubit,
              state: state,
              subscriptionCubit: subscriptionCubit,
            ),
          ),
        );
      case CreateFlightStep.wikipediaArticles:
        return FlightSearchWikipediaArticlesStep(
          state: state,
          isProUser: isProUser,
          onToggleArticle: cubit.toggleWikiArticleSelection,
          onToggleAll: cubit.toggleAllWikiArticleSelections,
          onStartDownload: () => unawaited(
            _handleStartDownload(
              context: context,
              state: state,
              cubit: cubit,
              subscriptionCubit: subscriptionCubit,
            ),
          ),
        );
    }
  }

  Future<void> _showRouteNoteDialog(
    BuildContext context,
    FlightPreviewState state,
  ) async {
    final entryFlightNumber = context.read<FlightPreviewCubit>().flightNumber;
    final isHistoricalTrack =
        state.flightRoute?.isHistoricalTrack ??
        (entryFlightNumber != null && entryFlightNumber.trim().isNotEmpty);
    final overviewT = context.t.createFlight.overview;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isHistoricalTrack
                ? overviewT.realRouteNoteTitle
                : overviewT.routeNoteTitle,
          ),
          content: Text(
            isHistoricalTrack
                ? overviewT.realRouteNoteBody
                : overviewT.routeNoteBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.t.common.ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleUpgradeToProFromOverview({
    required BuildContext context,
    required FlightPreviewCubit cubit,
    required FlightPreviewState state,
    required SubscriptionCubit subscriptionCubit,
  }) async {
    if (subscriptionCubit.state.isPro) {
      return;
    }
    await showFlightUnlockGateSheet(
      context: context,
      subscriptionCubit: subscriptionCubit,
      source: PaywallSource.routeOverviewGate,
      onUnlockActivated: () async {
        await cubit.enablePendingFlightUnlock();
        if (context.mounted) {
          await maybeShowRouteUpgradeChoiceSheet(
            context: context,
            cubit: cubit,
            source: PaywallSource.routeOverviewGate,
          );
        }
      },
      onProActivated: () async {
        await cubit.refreshPoisForPro();
        if (context.mounted) {
          await maybeShowRouteUpgradeChoiceSheet(
            context: context,
            cubit: cubit,
            source: PaywallSource.routeOverviewGate,
          );
        }
      },
      routePreview: _routePreviewText(state),
      presentProPaywall: subscriptionCubit.presentPaywallFromRouteOverviewGate,
    );
  }

  Future<void> _handleStartDownload({
    required BuildContext context,
    required FlightPreviewState state,
    required FlightPreviewCubit cubit,
    required SubscriptionCubit subscriptionCubit,
  }) async {
    final isProUser =
        subscriptionCubit.state.isPro || state.hasPendingFlightUnlock;
    final selectedCount = state.selectedArticleUrls.length;
    final needsArticleTierUpgrade =
        !isProUser && selectedCount > ProLimits.freeWikiArticlesSelectionLimit;
    if (!needsArticleTierUpgrade) {
      await cubit.startDownload();
      return;
    }

    await showFlightUnlockGateSheet(
      context: context,
      subscriptionCubit: subscriptionCubit,
      source: PaywallSource.wikiLimit,
      onUnlockActivated: () async {
        await cubit.enablePendingFlightUnlock();
      },
      onProActivated: cubit.refreshPoisForPro,
      routePreview: _routePreviewText(state),
      presentProPaywall: subscriptionCubit.presentPaywallForCreateFlight,
    );
  }

  String? _routePreviewText(FlightPreviewState state) {
    final route = state.flightRoute;
    if (route == null) return null;
    return '${route.departure.nameShort} → ${route.arrival.nameShort}';
  }

  Future<void> _onBackPressed(BuildContext context) async {
    final shouldPop = await context
        .read<FlightPreviewCubit>()
        .handleBackAction();
    if (shouldPop && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showOverviewWarningDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final previewCubit = context.read<FlightPreviewCubit>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.t.common.ok),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    _isShowingOverviewWarning = false;
    previewCubit.dismissOverviewWarning();
  }

  void _handleDownloadCompleted(FlightPreviewState state) {
    unawaited(
      GetIt.I.get<RatePromptPolicyService>().registerTrigger(
        RatePromptTrigger.flightMapDownloadSuccess,
      ),
    );
    final flightId = state.savedFlightId;
    if (flightId == null || flightId.isEmpty) {
      _showSnackBar(context, context.t.preview.errorSomethingWrong);
      AppRouter.goHome(context);
      return;
    }
    final isProSubscriber = context.read<SubscriptionCubit>().state.isPro;
    AppRouter.goToDownloadCompleted(
      context,
      flightId: flightId,
      isProSubscriber: isProSubscriber,
      usedSingleFlightUnlock: state.usedSingleFlightUnlock && !isProSubscriber,
    );
  }

  int _stepIndex(CreateFlightStep step) {
    return switch (step) {
      CreateFlightStep.routeNotSupported => 0,
      CreateFlightStep.overview => 0,
      CreateFlightStep.wikipediaArticles => 1,
    };
  }

  List<Widget>? _buildAppBarActions(
    BuildContext context, {
    required FlightPreviewState state,
    required _ProAccessInfo? proAccessInfo,
  }) {
    final actions = <Widget>[
      if (proAccessInfo != null)
        ProAppBarInfoButton(
          title: proAccessInfo.title,
          message: proAccessInfo.message,
          tooltip: context.t.createFlight.proAccess.tooltip,
        ),
      if (state.step == CreateFlightStep.overview)
        IconButton(
          tooltip: context.t.createFlight.overview.routeNoteTooltip,
          onPressed: () => _showRouteNoteDialog(context, state),
          icon: const Icon(Icons.info_outline_rounded),
        ),
    ];
    return actions.isEmpty ? null : actions;
  }

  _ProAccessInfo? _proAccessInfo(
    BuildContext context, {
    required bool isProSubscriber,
    required bool hasPendingFlightUnlock,
  }) {
    if (isProSubscriber) {
      return _ProAccessInfo(
        title: context.t.createFlight.proAccess.subscriber,
        message: context.t.createFlight.proAccess.subscriberBody,
      );
    }
    if (hasPendingFlightUnlock) {
      return _ProAccessInfo(
        title: context.t.createFlight.proAccess.unlockedFlight,
        message: context.t.createFlight.proAccess.unlockedFlightBody,
      );
    }
    return null;
  }

  String _titleForState(BuildContext context, FlightPreviewState state) {
    if (state.isDownloading) {
      return context.t.preview.downloadingMapTitle;
    }
    final step = state.step;
    return switch (step) {
      CreateFlightStep.routeNotSupported =>
        context.t.createFlight.steps.routeNotSupportedTitle,
      CreateFlightStep.overview => context.t.createFlight.steps.overviewTitle,
      CreateFlightStep.wikipediaArticles =>
        context.t.createFlight.steps.wikipediaTitle,
    };
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProAccessInfo {
  const _ProAccessInfo({required this.title, required this.message});

  final String title;
  final String message;
}
