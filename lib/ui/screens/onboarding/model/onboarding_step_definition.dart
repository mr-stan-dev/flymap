import 'package:flutter/material.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_cubit.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

enum OnboardingStepId {
  welcome,
  name,
  frequency,
  homeAirport,
  interests,
  pro,
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
  });

  final OnboardingStepId id;
  final OnboardingStepWidgetBuilder stepBuilder;
  final String Function(
    BuildContext context,
    OnboardingProfileFormState state,
    SubscriptionState subscriptionState,
  )
  primaryActionLabel;
  final bool Function(OnboardingProfileFormState state) canContinue;

  Widget build(
    BuildContext context,
    OnboardingProfileFormCubit cubit,
    OnboardingProfileFormState state,
  ) {
    return stepBuilder(context, cubit, state);
  }
}
