import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_category_card.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_category_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_state.dart';

class LearnTab extends StatelessWidget {
  const LearnTab({super.key, this.cubit});

  final LearnCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LearnCubit>(
      create: (_) => (cubit ?? LearnCubit())..load(),
      child: const _LearnCategoriesView(),
    );
  }
}

class _LearnCategoriesView extends StatelessWidget {
  const _LearnCategoriesView();

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
            if (categories.isEmpty) {
              return EmptyStateView(
                title: context.t.learn.emptyCategoriesTitle,
                subtitle: context.t.learn.emptyCategoriesSubtitle,
                icon: Icons.menu_book_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                return LearnCategoryCard(
                  category: category,
                  onTap: () {
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
              itemCount: categories.length,
            );
        }
      },
    );
  }
}
