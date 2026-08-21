import 'dart:async';

import 'package:flymap/analytics/app_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/experiments/onboarding_experiment_service.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/feature_announcement_repository.dart';
import 'package:flymap/repository/home_area_overview_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/model/onboarding_step_definition.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_area_payoff_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_home_airport_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_interests_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_social_proof_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_weather_payoff_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_welcome_step.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_cubit.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:get_it/get_it.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.experimentService});

  final OnboardingExperimentService? experimentService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingProfileFormCubit(
        repository: GetIt.I<OnboardingRepository>(),
        airportsDb: GetIt.I<AirportsDatabase>(),
        favoritesRepository: GetIt.I<FavoriteAirportsRepository>(),
        recentAirportsRepository: GetIt.I<RecentAirportsRepository>(),
        featureAnnouncementRepository:
            GetIt.I.isRegistered<FeatureAnnouncementRepository>()
            ? GetIt.I<FeatureAnnouncementRepository>()
            : null,
        homeAreaRepository: GetIt.I.isRegistered<HomeAreaOverviewRepository>()
            ? GetIt.I<HomeAreaOverviewRepository>()
            : null,
      ),
      child: _OnboardingFlowView(experimentService: experimentService),
    );
  }
}

class _OnboardingFlowView extends StatefulWidget {
  const _OnboardingFlowView({this.experimentService});

  final OnboardingExperimentService? experimentService;

  @override
  State<_OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends State<_OnboardingFlowView> {
  static const String _flowVersion = 'v7_platform_experiments';
  static const String _entrySource = 'app_launch';

  final AppAnalytics _analytics = GetIt.I<AppAnalytics>();
  final DateTime _startedAt = DateTime.now();

  int _stepIndex = 0;
  bool _isFinishing = false;
  int _stepsSkippedCount = 0;
  String? _lastTrackedStepId;
  int? _lastTrackedStepIndex;
  OnboardingExperimentAssignment? _experiment;

  List<OnboardingStepDefinition> _steps(
    OnboardingExperimentAssignment experiment,
  ) => [
    OnboardingStepDefinition(
      id: OnboardingStepId.welcome,
      stepBuilder: (context, __, ___) => OnboardingWelcomeStep(),
      primaryActionLabel: (context, _) => context.t.onboarding.letsStart,
      canContinue: (_) => true,
    ),
    OnboardingStepDefinition(
      id: OnboardingStepId.interests,
      stepBuilder: (context, cubit, state) => OnboardingInterestsStep(
        title: context.t.onboarding.interestsTitle,
        subtitle: context.t.onboarding.interestsSubtitle,
        selectedInterests: state.profile.interests,
        onToggleInterest: cubit.toggleInterest,
      ),
      primaryActionLabel: (context, _) => context.t.common.kContinue,
      canContinue: (_) => true,
    ),
    OnboardingStepDefinition(
      id: OnboardingStepId.homeAirport,
      stepBuilder: (context, cubit, state) => OnboardingHomeAirportStep(
        title: context.t.onboarding.homeAirportTitle,
        subtitle: context.t.onboarding.homeAirportSubtitle,
        selectedAirport: state.homeAirport,
        query: state.airportQuery,
        isSearchLoading: state.isAirportSearchLoading,
        results: state.airportSearchResults,
        popular: state.popularAirports,
        errorMessage: state.errorMessage,
        onQueryChanged: cubit.searchHomeAirports,
        onSelectAirport: (airport) =>
            cubit.selectHomeAirport(airport, addToFavorites: false),
        onClearSelectedAirport: cubit.clearHomeAirport,
      ),
      primaryActionLabel: (context, _) => context.t.common.kContinue,
      canContinue: (state) => state.homeAirport != null,
      // The payoff step depends on the home airport, so it can't be
      // skipped.
      isSkippable: false,
    ),
    OnboardingStepDefinition(
      id: OnboardingStepId.areaPayoff,
      stepBuilder: (context, _, state) => OnboardingAreaPayoffStep(
        airport: state.homeAirport,
        status: state.homeAreaStatus,
        summary: state.homeAreaSummary,
      ),
      primaryActionLabel: (context, _) => context.t.common.kContinue,
      canContinue: (_) => true,
    ),
    // The final feature payoff: the real animated cloud map on canned
    // routes, optionally followed by social proof before subscription.
    OnboardingStepDefinition(
      id: OnboardingStepId.weatherPayoff,
      stepBuilder: (context, _, __) => const OnboardingWeatherPayoffStep(),
      primaryActionLabel: (context, _) => context.t.common.kContinue,
      canContinue: (_) => true,
    ),
    if (experiment.showSocialProof)
      OnboardingStepDefinition(
        id: OnboardingStepId.socialProof,
        stepBuilder: (context, _, __) => const OnboardingSocialProofStep(),
        primaryActionLabel: (context, _) => context.t.common.kContinue,
        canContinue: (_) => true,
        isSkippable: false,
      ),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_resolveExperiment());
  }

  @override
  Widget build(BuildContext context) {
    final experiment = _experiment;
    if (experiment == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final steps = _steps(experiment);
    final isLastStep = _stepIndex == steps.length - 1;

    return BlocBuilder<OnboardingProfileFormCubit, OnboardingProfileFormState>(
      builder: (context, state) {
        final currentStep = steps[_stepIndex];
        final canContinue =
            !_isFinishing && !state.isLoading && currentStep.canContinue(state);
        final isSkippable = !isLastStep && currentStep.isSkippable;
        _trackStepViewed(stepId: currentStep.id, isSkippable: isSkippable);

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: _stepIndex == 0
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                    ),
                                    onPressed: _isFinishing
                                        ? null
                                        : () {
                                            setState(() {
                                              _stepIndex -= 1;
                                            });
                                          },
                                  ),
                          ),
                        ),
                        OnboardingProgressIndicator(
                          count: steps.length,
                          activeIndex: _stepIndex,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: isSkippable
                              ? TertiaryButton(
                                  label: context.t.onboarding.skip,
                                  onPressed: _isFinishing
                                      ? null
                                      : () => _skipCurrentStep(
                                          currentStepId: currentStep.id,
                                        ),
                                  expand: false,
                                )
                              : const SizedBox(width: 44, height: 44),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedSwitcher(
                          duration: DsMotion.normal,
                          switchInCurve: DsMotion.enter,
                          switchOutCurve: DsMotion.exit,
                          child: KeyedSubtree(
                            key: ValueKey(currentStep.id),
                            child: currentStep.build(
                              context,
                              context.read<OnboardingProfileFormCubit>(),
                              state,
                            ),
                          ),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: _buildBottomActions(
                    context,
                    currentStep: currentStep,
                    state: state,
                    canContinue: canContinue,
                    isLastStep: isLastStep,
                    stepsTotal: steps.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(
    BuildContext context, {
    required OnboardingStepDefinition currentStep,
    required OnboardingProfileFormState state,
    required bool canContinue,
    required bool isLastStep,
    required int stepsTotal,
  }) {
    final cubit = context.read<OnboardingProfileFormCubit>();
    final onContinuePressed = canContinue
        ? () => _handlePrimary(
            cubit,
            currentStepId: currentStep.id,
            isLastStep: isLastStep,
            state: state,
            stepsTotal: stepsTotal,
          )
        : null;

    return PrimaryButton(
      label: currentStep.primaryActionLabel(context, state),
      isLoading: _isFinishing,
      onPressed: onContinuePressed,
    );
  }

  Future<void> _handlePrimary(
    OnboardingProfileFormCubit cubit, {
    required OnboardingStepId currentStepId,
    required bool isLastStep,
    required OnboardingProfileFormState state,
    required int stepsTotal,
  }) async {
    _trackStepCompleted(currentStepId, state);
    if (isLastStep) {
      await _finish(cubit, stepsTotal: stepsTotal);
      return;
    }
    if (currentStepId == OnboardingStepId.homeAirport) {
      await cubit.addSelectedHomeAirportToFavorites();
    }
    setState(() {
      _stepIndex += 1;
    });
  }

  /// Finishes the assigned onboarding steps, optionally presents the real
  /// paywall, then continues into first flight creation regardless of the
  /// outcome — the paywall never blocks onboarding.
  Future<void> _finish(
    OnboardingProfileFormCubit cubit, {
    required int stepsTotal,
  }) async {
    setState(() {
      _isFinishing = true;
    });
    final subscriptionCubit = context.read<SubscriptionCubit>();
    SubscriptionPaywallResult? paywallResult;
    final experiment = _experiment;
    if (!subscriptionCubit.state.isPro &&
        (experiment?.showOnboardingPaywall ?? true)) {
      try {
        paywallResult = await subscriptionCubit.presentPaywallFromOnboarding();
      } catch (_) {
        // Whatever happens to the paywall, onboarding must complete.
      }
    }
    await cubit.completeOnboarding();
    final durationSec = DateTime.now().difference(_startedAt).inSeconds;
    unawaited(
      _analytics.log(
        OnboardingCompletedEvent(
          flowVersion: _flowVersion,
          stepsTotal: stepsTotal,
          stepsSkippedCount: _stepsSkippedCount,
          durationSec: durationSec,
          experimentKey: experiment?.experimentKey,
          experimentVariant: experiment?.analyticsVariant,
          experimentEnrolled: experiment?.isEnrolled,
        ),
      ),
    );
    if (!mounted) return;
    if (paywallResult == SubscriptionPaywallResult.purchased ||
        paywallResult == SubscriptionPaywallResult.restored) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.settings.flymapProActivated)),
      );
    }
    AppRouter.goToRouteTypeSelectorFromOnboarding(context);
  }

  Future<void> _resolveExperiment() async {
    final service =
        widget.experimentService ??
        (GetIt.I.isRegistered<OnboardingExperimentService>()
            ? GetIt.I<OnboardingExperimentService>()
            : null);
    final assignment = service == null
        ? OnboardingExperimentAssignment.currentExperience(
            defaultTargetPlatform,
          )
        : await service.resolve(defaultTargetPlatform);
    if (!mounted) return;
    setState(() {
      _experiment = assignment;
    });
    unawaited(
      _analytics.log(
        OnboardingStartedEvent(
          flowVersion: _flowVersion,
          entrySource: _entrySource,
          experimentKey: assignment.experimentKey,
          experimentVariant: assignment.analyticsVariant,
          experimentEnrolled: assignment.isEnrolled,
        ),
      ),
    );
  }

  Future<void> _skipCurrentStep({
    required OnboardingStepId currentStepId,
  }) async {
    if (_isFinishing) return;
    _stepsSkippedCount += 1;
    unawaited(
      _analytics.log(
        OnboardingStepSkippedEvent(
          stepId: currentStepId.name,
          stepIndex: _currentStepOrdinal,
        ),
      ),
    );
    setState(() {
      _stepIndex += 1;
    });
  }

  void _trackStepViewed({
    required OnboardingStepId stepId,
    required bool isSkippable,
  }) {
    if (_lastTrackedStepId == stepId.name &&
        _lastTrackedStepIndex == _currentStepOrdinal) {
      return;
    }
    _lastTrackedStepId = stepId.name;
    _lastTrackedStepIndex = _currentStepOrdinal;
    unawaited(
      _analytics.log(
        OnboardingStepViewedEvent(
          stepId: stepId.name,
          stepIndex: _currentStepOrdinal,
          isSkippable: isSkippable,
        ),
      ),
    );
  }

  void _trackStepCompleted(
    OnboardingStepId stepId,
    OnboardingProfileFormState state,
  ) {
    unawaited(
      _analytics.log(
        OnboardingStepCompletedEvent(
          stepId: stepId.name,
          stepIndex: _currentStepOrdinal,
          inputState: _inputStateForStep(stepId, state),
        ),
      ),
    );
  }

  int get _currentStepOrdinal => _stepIndex + 1;

  String _inputStateForStep(
    OnboardingStepId stepId,
    OnboardingProfileFormState state,
  ) {
    return switch (stepId) {
      OnboardingStepId.welcome => 'none',
      OnboardingStepId.homeAirport =>
        state.homeAirport == null ? 'empty' : 'selected',
      OnboardingStepId.interests =>
        'selected_${state.profile.interests.length}',
      OnboardingStepId.areaPayoff => switch (state.homeAreaStatus) {
        HomeAreaSummaryStatus.ready =>
          'ready_${state.homeAreaSummary?.totalPlaces ?? 0}',
        HomeAreaSummaryStatus.loading => 'loading',
        HomeAreaSummaryStatus.failed => 'failed',
        HomeAreaSummaryStatus.none => 'fallback',
      },
      // Pure showcase — nothing the user inputs.
      OnboardingStepId.weatherPayoff => 'none',
      OnboardingStepId.socialProof => 'none',
    };
  }
}
