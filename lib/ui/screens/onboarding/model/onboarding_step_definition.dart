import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_cubit.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';

enum OnboardingStepId {
  welcome,
  interests,
  homeAirport,
  areaPayoff,
  weatherPayoff,
  socialProof,
}

typedef OnboardingStepWidgetBuilder =
    Widget Function(
      BuildContext context,
      OnboardingProfileFormCubit cubit,
      OnboardingProfileFormState state,
    );

class OnboardingStepDefinition {
  const OnboardingStepDefinition({
    required this.id,
    required this.stepBuilder,
    required this.primaryActionLabel,
    required this.canContinue,
    this.isSkippable = true,
  });

  final OnboardingStepId id;
  final OnboardingStepWidgetBuilder stepBuilder;
  final String Function(BuildContext context, OnboardingProfileFormState state)
  primaryActionLabel;
  final bool Function(OnboardingProfileFormState state) canContinue;

  /// Whether the header Skip button is offered for this step (never offered
  /// on the last step regardless).
  final bool isSkippable;

  Widget build(
    BuildContext context,
    OnboardingProfileFormCubit cubit,
    OnboardingProfileFormState state,
  ) {
    return stepBuilder(context, cubit, state);
  }
}
