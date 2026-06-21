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

class LearnTab extends StatelessWidget {
  const LearnTab({super.key, this.cubit, this.showGeoQuizNewBadge = false});

  final LearnCubit? cubit;
  final bool showGeoQuizNewBadge;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LearnCubit>(
          create: (_) => (cubit ?? LearnCubit())..load(),
        ),
        BlocProvider<GeoQuizListCubit>(
          create: (_) => GeoQuizListCubit()..load(),
        ),
      ],
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
                  return BlocBuilder<GeoQuizListCubit, GeoQuizListState>(
                    builder: (context, geoQuizState) {
                      final progress = _geoQuizProgress(geoQuizState);
                      return GeoQuizEntryCard(
                        finishedCount: progress.finished,
                        inProgressCount: progress.inProgress,
                        totalCount: progress.total,
                        showNewBadge: showGeoQuizNewBadge,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GeoQuizListScreen(),
                            ),
                          );
                          if (!context.mounted) return;
                          await context
                              .read<GeoQuizListCubit>()
                              .refreshProgress();
                        },
                      );
                    },
                  );
                }
                if (index == 2) {
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
                final category = categories[index - 3];
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
              itemCount: categories.isEmpty ? 4 : categories.length + 3,
            );
        }
      },
    );
  }

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
