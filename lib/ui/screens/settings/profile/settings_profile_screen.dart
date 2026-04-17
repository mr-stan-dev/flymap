import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/onboarding_profile.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/favorite_airports_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/recent_airports_repository.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/onboarding/model/onboarding_profile_ui.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_cubit.dart';
import 'package:flymap/ui/screens/onboarding/viewmodel/onboarding_profile_form_state.dart';
import 'package:flymap/ui/screens/onboarding/widgets/profile/interests_selector.dart';
import 'package:flymap/ui/screens/settings/profile/widgets/profile_home_airport_picker.dart';
import 'package:flymap/ui/screens/settings/widgets/setting_item.dart';
import 'package:flymap/ui/screens/settings/widgets/settings_bottom_sheet.dart';
import 'package:flymap/ui/screens/settings/widgets/settings_choice_section.dart';
import 'package:flymap/ui/screens/settings/widgets/settings_group_card.dart';
import 'package:flymap/ui/screens/settings/widgets/safe_bottom_sheet.dart';
import 'package:get_it/get_it.dart';

class SettingsProfileScreen extends StatelessWidget {
  const SettingsProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingProfileFormCubit(
        repository: GetIt.I<OnboardingRepository>(),
        airportsDb: GetIt.I<AirportsDatabase>(),
        favoritesRepository: GetIt.I<FavoriteAirportsRepository>(),
        recentAirportsRepository: GetIt.I<RecentAirportsRepository>(),
      ),
      child: const _SettingsProfileContent(),
    );
  }
}

class _SettingsProfileContent extends StatelessWidget {
  const _SettingsProfileContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t.settings.profile)),
      body: BlocBuilder<OnboardingProfileFormCubit, OnboardingProfileFormState>(
        builder: (context, state) {
          if (state.isLoading) {
            return LoadingStateView(title: context.t.settings.loading);
          }

          final cubit = context.read<OnboardingProfileFormCubit>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              _ProfileHeader(hint: context.t.settings.profileEditHint),
              const SizedBox(height: 12),
              SettingsGroupCard(
                title: context.t.settings.profile,
                children: [
                  SettingItem(
                    title: context.t.onboarding.nameTitle,
                    subtitle: _nameValue(context, state),
                    leading: const Icon(Icons.person_outline_rounded),
                    onTap: () => _openNameSheet(context, cubit, state),
                  ),
                  SettingItem(
                    title: context.t.onboarding.frequencyTitle,
                    subtitle: _frequencyValue(context, state),
                    leading: const Icon(Icons.flight_takeoff_rounded),
                    onTap: () => _openFrequencySheet(context, cubit, state),
                  ),
                  SettingItem(
                    title: context.t.onboarding.homeAirportTitle,
                    subtitle: _homeAirportValue(context, state),
                    leading: const Icon(Icons.home_work_outlined),
                    onTap: () => _openHomeAirportSheet(context, cubit),
                  ),
                  SettingItem(
                    title: context.t.onboarding.interestsTitle,
                    subtitle: _interestsValue(context, state),
                    leading: const Icon(Icons.interests_outlined),
                    onTap: () => _openInterestsSheet(context, cubit, state),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _nameValue(BuildContext context, OnboardingProfileFormState state) {
    final name = state.profile.displayName.trim();
    if (name.isEmpty) return context.t.settings.profileNotSet;
    return name;
  }

  String _frequencyValue(
    BuildContext context,
    OnboardingProfileFormState state,
  ) {
    final frequency = state.profile.flyingFrequency;
    if (frequency == null) return context.t.settings.profileNotSet;
    return frequency.title(context);
  }

  String _homeAirportValue(
    BuildContext context,
    OnboardingProfileFormState state,
  ) {
    final airport = state.homeAirport;
    if (airport == null) return context.t.settings.profileNotSet;
    return '${airport.nameShort} (${airport.displayCode})';
  }

  String _interestsValue(
    BuildContext context,
    OnboardingProfileFormState state,
  ) {
    final interests = state.profile.interests;
    if (interests.isEmpty) return context.t.settings.profileNotSet;
    if (interests.length == 1) return interests.first.label(context);
    return context.t.settings.profileInterestsSelected(count: interests.length);
  }

  Future<void> _openNameSheet(
    BuildContext context,
    OnboardingProfileFormCubit cubit,
    OnboardingProfileFormState state,
  ) async {
    final controller = TextEditingController(text: state.profile.displayName);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SettingsBottomSheet(
          title: context.t.onboarding.nameTitle,
          onConfirm: () async {
            await cubit.setDisplayName(controller.text.trim());
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
          },
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Alex',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
  }

  Future<void> _openFrequencySheet(
    BuildContext context,
    OnboardingProfileFormCubit cubit,
    OnboardingProfileFormState state,
  ) async {
    var selected = state.profile.flyingFrequency ?? FlyingFrequency.fewPerYear;
    final options = {
      for (final frequency in FlyingFrequency.values)
        frequency.title(context): frequency,
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var selectedLabel = selected.title(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SettingsBottomSheet(
              title: context.t.onboarding.frequencyTitle,
              onConfirm: () async {
                await cubit.setFlyingFrequency(selected);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
              child: SettingsChoiceSection(
                options: options.keys.toList(),
                current: selectedLabel,
                onChanged: (label) {
                  final mapped = options[label];
                  if (mapped == null) return;
                  setSheetState(() {
                    selected = mapped;
                    selectedLabel = label;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openInterestsSheet(
    BuildContext context,
    OnboardingProfileFormCubit cubit,
    OnboardingProfileFormState state,
  ) async {
    var selected = [...state.profile.interests];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SettingsBottomSheet(
              title: context.t.onboarding.interestsTitle,
              onConfirm: () async {
                await cubit.setInterests(selected);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
              child: InterestsSelector(
                selectedInterests: selected,
                onToggleInterest: (interest) {
                  setSheetState(() {
                    if (selected.contains(interest)) {
                      selected.remove(interest);
                    } else if (selected.length <
                        OnboardingProfileFormState.maxInterests) {
                      selected.add(interest);
                    }
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openHomeAirportSheet(
    BuildContext context,
    OnboardingProfileFormCubit cubit,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeBottomSheet(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FractionallySizedBox(
            heightFactor: 0.92,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.t.onboarding.homeAirportTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      BlocBuilder<
                        OnboardingProfileFormCubit,
                        OnboardingProfileFormState
                      >(
                        bloc: cubit,
                        builder: (context, state) {
                          return ProfileHomeAirportPicker(
                            selectedAirport: state.homeAirport,
                            query: state.airportQuery,
                            isSearchLoading: state.isAirportSearchLoading,
                            results: state.airportSearchResults,
                            popular: state.popularAirports,
                            errorMessage: state.errorMessage,
                            onQueryChanged: cubit.searchHomeAirports,
                            onSelectAirport: (airport) async {
                              await cubit.selectHomeAirport(airport);
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            onClearSelectedAirport: cubit.clearHomeAirport,
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune_rounded, color: colorScheme.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
