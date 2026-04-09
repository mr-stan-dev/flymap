import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/crashlytics/app_crashlytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/data/route/flight_route_provider.dart';
import 'package:flymap/entity/map_detail_level.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/rating/rate_prompt_policy_service.dart';
import 'package:flymap/rating/rate_prompt_trigger.dart';
import 'package:flymap/rating/rate_store_launcher.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/subscription/pro_limits.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/flight_preview_args.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/downloading/flight_search_downloading_view.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/map_preview/flight_search_map_preview_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/overview/flight_search_overview_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/route_not_supported/flight_search_route_not_supported_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/wikipedia_articles/flight_search_wikipedia_articles_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_cubit.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/flight_download_completion.dart';
import 'package:flymap/ui/screens/home/tabs/home/home_tab.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/widgets/rate_app_dialog.dart';
import 'package:flymap/usecase/download_map_use_case.dart';
import 'package:flymap/usecase/download_poi_summaries_use_case.dart';
import 'package:flymap/usecase/download_wikipedia_articles_use_case.dart';
import 'package:flymap/usecase/get_flight_info_use_case.dart';
import 'package:flymap/usecase/delete_flight_use_case.dart';
import 'package:flymap/usecase/get_flight_poi_use_case.dart';
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
        connectivityChecker: GetIt.I.get<ConnectivityChecker>(),
        routeProvider: GetIt.I.get<FlightRouteProvider>(),
        downloadMapUseCase: GetIt.I.get<DownloadMapUseCase>(),
        downloadPoiSummariesUseCase: GetIt.I.get<DownloadPoiSummariesUseCase>(),
        downloadWikipediaArticlesUseCase: GetIt.I
            .get<DownloadWikipediaArticlesUseCase>(),
        getFlightInfoUseCase: GetIt.I.get<GetFlightInfoUseCase>(),
        getFlightPOIUseCase: GetIt.I.get<GetFlightPOIUseCase>(),
        flightRepository: GetIt.I.get<FlightRepository>(),
        subscriptionRepository: GetIt.I.get<SubscriptionRepository>(),
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
  bool _showDownloadSuccess = false;
  bool _downloadCompletionHandled = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FlightPreviewCubit, FlightPreviewState>(
      listenWhen: (previous, current) {
        return previous.errorMessage != current.errorMessage ||
            previous.downloadErrorMessage != current.downloadErrorMessage ||
            previous.downloadDone != current.downloadDone ||
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
          unawaited(_handleDownloadCompleted());
        }
      },
      builder: (context, state) {
        final isProUser = context.select(
          (SubscriptionCubit cubit) => cubit.state.isPro,
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
    if (_showDownloadSuccess) {
      return const FlightDownloadCompletion();
    }

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
      case CreateFlightStep.mapPreview:
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
        return FlightSearchMapPreviewStep(
          state: state,
          isProUser: isProUser,
          onContinue: () => unawaited(
            _handleContinueFromMap(
              context: context,
              state: state,
              cubit: cubit,
              subscriptionCubit: subscriptionCubit,
            ),
          ),
          onSelectMapDetailLevel: cubit.selectMapDetailLevel,
        );
      case CreateFlightStep.overview:
        return FlightSearchOverviewStep(
          state: state,
          isProUser: isProUser,
          onContinue: cubit.continueFromOverview,
          onUpgradeToPro: () => unawaited(
            _handleUpgradeFromOverview(
              context: context,
              cubit: cubit,
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

  Future<void> _handleContinueFromMap({
    required BuildContext context,
    required FlightPreviewState state,
    required FlightPreviewCubit cubit,
    required SubscriptionCubit subscriptionCubit,
  }) async {
    final isProUser = subscriptionCubit.state.isPro;
    final shouldUpgradeFirst =
        !isProUser && state.selectedMapDetailLevel == MapDetailLevel.pro;
    if (!shouldUpgradeFirst) {
      await cubit.continueFromMap();
      return;
    }

    final result = await subscriptionCubit.presentPaywallForCreateFlight(
      shouldUpgradeForArticles: false,
      shouldUpgradeForMapConfig: true,
    );
    if (!context.mounted) return;

    switch (result) {
      case SubscriptionPaywallResult.purchased:
      case SubscriptionPaywallResult.restored:
        _showSnackBar(context, context.t.settings.flymapProActivated);
        return;
      case SubscriptionPaywallResult.cancelled:
        _showSnackBar(context, context.t.createFlight.paywall.upgradeCancelled);
        return;
      case SubscriptionPaywallResult.notPresented:
        _showSnackBar(context, context.t.createFlight.paywall.noPaywall);
        return;
      case SubscriptionPaywallResult.error:
        _showSnackBar(
          context,
          context.t.createFlight.paywall.failedOpenPaywall,
        );
        return;
    }
  }

  Future<void> _handleStartDownload({
    required BuildContext context,
    required FlightPreviewState state,
    required FlightPreviewCubit cubit,
    required SubscriptionCubit subscriptionCubit,
  }) async {
    final isProUser = subscriptionCubit.state.isPro;
    final selectedCount = state.selectedArticleUrls.length;
    final shouldUpgradeForArticles =
        !isProUser && selectedCount > ProLimits.freeWikiArticlesSelectionLimit;
    final shouldUpgradeForMapConfig =
        !isProUser && state.selectedMapDetailLevel == MapDetailLevel.pro;
    final shouldUpgradeFirst =
        shouldUpgradeForArticles || shouldUpgradeForMapConfig;
    if (!shouldUpgradeFirst) {
      await cubit.startDownload();
      return;
    }

    final result = await subscriptionCubit.presentPaywallForCreateFlight(
      shouldUpgradeForArticles: shouldUpgradeForArticles,
      shouldUpgradeForMapConfig: shouldUpgradeForMapConfig,
    );
    if (!context.mounted) return;

    switch (result) {
      case SubscriptionPaywallResult.purchased:
      case SubscriptionPaywallResult.restored:
        _showSnackBar(context, context.t.settings.flymapProActivated);
        return;
      case SubscriptionPaywallResult.cancelled:
        _showSnackBar(context, context.t.createFlight.paywall.upgradeCancelled);
        return;
      case SubscriptionPaywallResult.notPresented:
        _showSnackBar(context, context.t.createFlight.paywall.noPaywall);
        return;
      case SubscriptionPaywallResult.error:
        _showSnackBar(
          context,
          context.t.createFlight.paywall.failedOpenPaywall,
        );
        return;
    }
  }

  Future<void> _handleUpgradeFromOverview({
    required BuildContext context,
    required FlightPreviewCubit cubit,
    required SubscriptionCubit subscriptionCubit,
  }) async {
    final result = await subscriptionCubit.presentPaywallFromOverviewPoi();
    if (!context.mounted) return;

    switch (result) {
      case SubscriptionPaywallResult.purchased:
      case SubscriptionPaywallResult.restored:
        await cubit.refreshPoisForPro();
        if (!context.mounted) return;
        _showSnackBar(context, context.t.settings.flymapProActivated);
        return;
      case SubscriptionPaywallResult.cancelled:
        _showSnackBar(context, context.t.createFlight.paywall.upgradeCancelled);
        return;
      case SubscriptionPaywallResult.notPresented:
        _showSnackBar(context, context.t.createFlight.paywall.noPaywall);
        return;
      case SubscriptionPaywallResult.error:
        _showSnackBar(
          context,
          context.t.createFlight.paywall.failedOpenPaywall,
        );
        return;
    }
  }

  Future<void> _onBackPressed(BuildContext context) async {
    final shouldPop = await context
        .read<FlightPreviewCubit>()
        .handleBackAction();
    if (shouldPop && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDownloadCompleted() async {
    if (!mounted) return;
    setState(() {
      _showDownloadSuccess = true;
    });

    // Keep the success state visible first, then ask for feedback
    // right before the home navigation.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    await _maybeShowRateDialog();
    if (!mounted) return;

    homeRefreshNotifier.value = true;
    AppRouter.goHome(context);
  }

  Future<void> _maybeShowRateDialog() async {
    final policy = GetIt.I.get<RatePromptPolicyService>();
    final shouldShow = await policy.registerTriggerAndShouldShow(
      RatePromptTrigger.flightMapDownloadSuccess,
    );
    if (!shouldShow || !mounted) return;

    final likedApp = await RateAppDialog.show(context);
    final action = likedApp == true
        ? 'yes'
        : likedApp == false
        ? 'no'
        : 'dismiss';
    unawaited(
      GetIt.I.get<AppAnalytics>().log(
        RatePromptActionEvent(
          source: RatePromptTrigger.flightMapDownloadSuccess.name,
          action: action,
        ),
      ),
    );
    if (likedApp == true) {
      await policy.recordAccepted();
      final opened = await GetIt.I.get<RateStoreLauncher>().openStoreListing();
      if (!opened && mounted) {
        _showSnackBar(context, context.t.settings.couldNotOpenStorePage);
      }
      return;
    }

    await policy.recordDeclined();
    if (!mounted) return;
    final submitted = await AppRouter.goToFeedback(
      context,
      source: 'rate_prompt_declined',
      isPro: context.read<SubscriptionCubit>().state.isPro,
    );
    if (!mounted || !submitted) return;
    _showSnackBar(context, context.t.settings.feedbackThanks);
  }

  int _stepIndex(CreateFlightStep step) {
    return switch (step) {
      CreateFlightStep.mapPreview => 0,
      CreateFlightStep.routeNotSupported => 0,
      CreateFlightStep.overview => 1,
      CreateFlightStep.wikipediaArticles => 2,
    };
  }

  String _titleForState(BuildContext context, FlightPreviewState state) {
    if (state.isDownloading) {
      return context.t.preview.downloadingMapTitle;
    }
    final step = state.step;
    return switch (step) {
      CreateFlightStep.mapPreview =>
        context.t.createFlight.steps.mapPreviewTitle,
      CreateFlightStep.routeNotSupported =>
        context.t.createFlight.steps.mapPreviewTitle,
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
