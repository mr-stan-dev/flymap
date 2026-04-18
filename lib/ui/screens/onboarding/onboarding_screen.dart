import 'dart:async';

import 'package:flymap/analytics/app_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/model/onboarding_step_definition.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_frequency_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_home_airport_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_interests_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_name_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_pro_step.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_welcome_step.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_cubit.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';
import 'package:flymap/ui/screens/onboarding/widgets/onboarding_progress_indicator.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';
import 'package:get_it/get_it.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingProfileFormCubit(
        repository: GetIt.I<OnboardingRepository>(),
        airportsDb: GetIt.I<AirportsDatabase>(),
        favoritesRepository: GetIt.I<FavoriteAirportsRepository>(),
        recentAirportsRepository: GetIt.I<RecentAirportsRepository>(),
      ),
      child: const _OnboardingFlowView(),
    );
  }
}

class _OnboardingFlowView extends StatefulWidget {
  const _OnboardingFlowView();

  @override
  State<_OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends State<_OnboardingFlowView> {
  static const String _flowVersion = 'v2_profile';
  static const String _entrySource = 'app_launch';

  final AppAnalytics _analytics = GetIt.I<AppAnalytics>();
  final DateTime _startedAt = DateTime.now();

  int _stepIndex = 0;
  bool _isFinishing = false;
  int _stepsSkippedCount = 0;
  String? _lastTrackedStepId;
  int? _lastTrackedStepIndex;

  List<OnboardingStepDefinition> _steps(SubscriptionState subscriptionState) =>
      [
        OnboardingStepDefinition(
          id: OnboardingStepId.welcome,
          stepBuilder: (context, __, ___) => OnboardingWelcomeStep(
            title: context.t.onboarding.welcomeTitle,
            tagline: context.t.onboarding.welcomeSubtitle,
          ),
          primaryActionLabel: (context, _, __) =>
              context.t.onboarding.letsStart,
          canContinue: (_) => true,
        ),
        OnboardingStepDefinition(
          id: OnboardingStepId.frequency,
          stepBuilder: (context, cubit, state) => OnboardingFrequencyStep(
            title: context.t.onboarding.frequencyTitle,
            subtitle: context.t.onboarding.frequencySubtitle,
            selectedFrequency: state.profile.flyingFrequency,
            onChanged: cubit.setFlyingFrequency,
          ),
          primaryActionLabel: (context, _, __) => context.t.common.kContinue,
          canContinue: (state) => state.profile.flyingFrequency != null,
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
          primaryActionLabel: (context, _, __) => context.t.common.kContinue,
          canContinue: (state) => state.homeAirport != null,
        ),
        OnboardingStepDefinition(
          id: OnboardingStepId.interests,
          stepBuilder: (context, cubit, state) => OnboardingInterestsStep(
            title: context.t.onboarding.interestsTitle,
            subtitle: context.t.onboarding.interestsSubtitle,
            selectedInterests: state.profile.interests,
            onToggleInterest: cubit.toggleInterest,
          ),
          primaryActionLabel: (context, _, __) => context.t.common.kContinue,
          canContinue: (_) => true,
        ),
        OnboardingStepDefinition(
          id: OnboardingStepId.name,
          stepBuilder: (context, cubit, state) => OnboardingNameStep(
            title: context.t.onboarding.nameTitle,
            subtitle: context.t.onboarding.nameSubtitle,
            initialValue: state.profile.displayName,
            onChanged: cubit.setDisplayName,
          ),
          primaryActionLabel: (context, _, __) => context.t.common.kContinue,
          canContinue: (state) => state.profile.displayName.trim().isNotEmpty,
        ),
        OnboardingStepDefinition(
          id: OnboardingStepId.pro,
          stepBuilder: (context, _, __) => OnboardingProStep(
            title: subscriptionState.isPro
                ? context.t.onboarding.proActiveTitle
                : context.t.onboarding.proTitle,
            isPro: subscriptionState.isPro,
            onTryPro: () => _tryPro(context),
          ),
          primaryActionLabel: (context, _, subscriptionState) =>
              subscriptionState.isPro
              ? context.t.onboarding.planFirstFlightPro
              : context.t.onboarding.planFirstFlight,
          canContinue: (_) => true,
        ),
      ];

  @override
  void initState() {
    super.initState();
    unawaited(
      _analytics.log(
        const OnboardingStartedEvent(
          flowVersion: _flowVersion,
          entrySource: _entrySource,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = context.watch<SubscriptionCubit>().state;
    final steps = _steps(subscriptionState);
    final isLastStep = _stepIndex == steps.length - 1;

    return BlocBuilder<OnboardingProfileFormCubit, OnboardingProfileFormState>(
      builder: (context, state) {
        final currentStep = steps[_stepIndex];
        final canContinue =
            !_isFinishing && !state.isLoading && currentStep.canContinue(state);
        _trackStepViewed(stepId: currentStep.id, isSkippable: !isLastStep);

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
                          child: !isLastStep
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
                  child: PrimaryButton(
                    label: currentStep.primaryActionLabel(
                      context,
                      state,
                      subscriptionState,
                    ),
                    isLoading: _isFinishing,
                    onPressed: canContinue
                        ? () => _handlePrimary(
                            context.read(),
                            currentStepId: currentStep.id,
                            isLastStep: isLastStep,
                            state: state,
                            stepsTotal: steps.length,
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  Future<void> _finish(
    OnboardingProfileFormCubit cubit, {
    required int stepsTotal,
  }) async {
    setState(() {
      _isFinishing = true;
    });
    await cubit.completeOnboarding();
    final durationSec = DateTime.now().difference(_startedAt).inSeconds;
    unawaited(
      _analytics.log(
        OnboardingCompletedEvent(
          flowVersion: _flowVersion,
          stepsTotal: stepsTotal,
          stepsSkippedCount: _stepsSkippedCount,
          durationSec: durationSec,
        ),
      ),
    );
    if (!mounted) return;
    AppRouter.goToFlightSearch(context);
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

  Future<void> _tryPro(BuildContext context) async {
    final result = await context
        .read<SubscriptionCubit>()
        .presentPaywallFromOnboarding();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (result) {
      case SubscriptionPaywallResult.purchased:
      case SubscriptionPaywallResult.restored:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.flymapProActivated)),
        );
        return;
      case SubscriptionPaywallResult.cancelled:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.upgradeCancelled)),
        );
        return;
      case SubscriptionPaywallResult.notPresented:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.noPaywall)),
        );
        return;
      case SubscriptionPaywallResult.error:
        messenger.showSnackBar(
          SnackBar(content: Text(context.t.settings.failedOpenPaywall)),
        );
        return;
    }
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
      OnboardingStepId.frequency =>
        state.profile.flyingFrequency == null ? 'empty' : 'selected',
      OnboardingStepId.homeAirport =>
        state.homeAirport == null ? 'empty' : 'selected',
      OnboardingStepId.interests =>
        'selected_${state.profile.interests.length}',
      OnboardingStepId.name =>
        state.profile.displayName.trim().isEmpty ? 'empty' : 'filled',
      OnboardingStepId.pro =>
        context.read<SubscriptionCubit>().state.isPro ? 'is_pro' : 'free',
    };
  }
}
