import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/geo_quiz_entry_card.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/geo_quiz_list_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_state.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_category_card.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_category_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_state.dart';
import 'package:get_it/get_it.dart';

({int finished, int inProgress, int total}) _geoQuizProgress(
  GeoQuizListState state,
) {
  if (state is! GeoQuizListLoaded) {
    return (finished: 0, inProgress: 0, total: 0);
  }

  var finished = 0;
  var inProgress = 0;
  for (final quiz in state.quizzes) {
    final solved = state
        .progressFor(quiz.id)
        .solvedCount
        .clamp(0, quiz.totalCount)
        .toInt();
    if (quiz.totalCount > 0 && solved >= quiz.totalCount) {
      finished += 1;
    } else if (solved > 0) {
      inProgress += 1;
    }
  }

  return (
    finished: finished,
    inProgress: inProgress,
    total: state.quizzes.length,
  );
}

class LearnTab extends StatelessWidget {
  const LearnTab({super.key, this.cubit, this.showGeoQuizNewBadge = false});

  final LearnCubit? cubit;
  final bool showGeoQuizNewBadge;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LearnCubit>(
      create: (_) => (cubit ?? LearnCubit())..load(),
      child: _LearnCategoriesView(showGeoQuizNewBadge: showGeoQuizNewBadge),
    );
  }
}

class _LearnCategoriesView extends StatelessWidget {
  const _LearnCategoriesView({required this.showGeoQuizNewBadge});

  final bool showGeoQuizNewBadge;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LearnCubit, LearnState>(
      builder: (context, state) {
        switch (state) {
          case LearnLoading():
            return LoadingStateView(title: context.t.learn.loadingCategories);
          case LearnError(:final message):
            return ErrorStateView(
              title: context.t.learn.failedToLoadCategories,
              message: message,
              retryLabel: context.t.common.retry,
              onRetry: () => context.read<LearnCubit>().retry(),
            );
          case LearnLoaded(:final categories):
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _LearnSectionTitle(
                    title: context.t.learn.quizzesTitle,
                  );
                }
                if (index == 1) {
                  return _GeoQuizCollectionCardLoader(
                    collectionId: 'countries',
                    screenTitle: context.t.learn.geoQuiz.countriesTitle,
                    builder: (context, progress, openScreen) {
                      return GeoQuizEntryCard(
                        title: context.t.learn.geoQuiz.countriesTitle,
                        subtitle: context.t.learn.geoQuiz.subtitle,
                        imageAssetPath:
                            'assets/images/quiz/countries_quiz.webp',
                        imageKey: GeoQuizEntryCard.countriesImageKey,
                        finishedCount: progress.finished,
                        inProgressCount: progress.inProgress,
                        totalCount: progress.total,
                        showNewBadge: showGeoQuizNewBadge,
                        onTap: openScreen,
                      );
                    },
                  );
                }
                if (index == 2) {
                  return _GeoQuizCollectionCardLoader(
                    collectionId: 'geography',
                    screenTitle: context.t.learn.geoQuiz.geographyTitle,
                    builder: (context, progress, openScreen) {
                      return GeoQuizEntryCard(
                        title: context.t.learn.geoQuiz.geographyTitle,
                        subtitle: context.t.learn.geoQuiz.geographySubtitle,
                        imageAssetPath:
                            'assets/images/quiz/geography_quiz.webp',
                        imageKey: GeoQuizEntryCard.geographyImageKey,
                        finishedCount: progress.finished,
                        inProgressCount: progress.inProgress,
                        totalCount: progress.total,
                        onTap: openScreen,
                      );
                    },
                  );
                }
                if (index == 3) {
                  return _LearnSectionTitle(
                    title: context.t.learn.articlesTitle,
                  );
                }
                if (categories.isEmpty) {
                  return EmptyStateView(
                    title: context.t.learn.emptyCategoriesTitle,
                    subtitle: context.t.learn.emptyCategoriesSubtitle,
                    icon: Icons.menu_book_outlined,
                  );
                }
                final category = categories[index - 4];
                return LearnCategoryCard(
                  category: category,
                  onTap: () {
                    context.read<LearnCubit>().trackCategoryOpened(category);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<LearnCubit>(),
                          child: LearnCategoryScreen(category: category),
                        ),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: categories.isEmpty ? 5 : categories.length + 4,
            );
        }
      },
    );
  }
}

typedef _GeoQuizCollectionCardBuilder =
    Widget Function(
      BuildContext context,
      ({int finished, int inProgress, int total}) progress,
      Future<void> Function() openScreen,
    );

class _GeoQuizCollectionCardLoader extends StatelessWidget {
  const _GeoQuizCollectionCardLoader({
    required this.collectionId,
    required this.screenTitle,
    required this.builder,
  });

  final String collectionId;
  final String screenTitle;
  final _GeoQuizCollectionCardBuilder builder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GeoQuizListCubit>(
      create: (_) => GetIt.I<GeoQuizListCubit>(param1: collectionId)..load(),
      child: BlocBuilder<GeoQuizListCubit, GeoQuizListState>(
        builder: (context, state) {
          final progress = _geoQuizProgress(state);
          return builder(context, progress, () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GeoQuizListScreen(
                  collectionId: collectionId,
                  title: screenTitle,
                ),
              ),
            );
            if (!context.mounted) return;
            await context.read<GeoQuizListCubit>().refreshProgress();
          });
        },
      ),
    );
  }
}

class _LearnSectionTitle extends StatelessWidget {
  const _LearnSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
