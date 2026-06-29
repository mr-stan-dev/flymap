import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/geo_quiz_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/geo_quiz_summary_localization.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:get_it/get_it.dart';

class GeoQuizListScreen extends StatelessWidget {
  const GeoQuizListScreen({
    required this.collectionId,
    required this.title,
    super.key,
  });

  final String collectionId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GeoQuizListCubit>(
      create: (providerContext) => GetIt.I<GeoQuizListCubit>(
        param1: collectionId,
      )..open(isProUser: providerContext.read<SubscriptionCubit>().state.isPro),
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const SafeArea(child: _GeoQuizListBody()),
      ),
    );
  }
}

class _GeoQuizListBody extends StatelessWidget {
  const _GeoQuizListBody();

  @override
  Widget build(BuildContext context) {
    final isProUser = context.select(
      (SubscriptionCubit cubit) => cubit.state.isPro,
    );
    return BlocBuilder<GeoQuizListCubit, GeoQuizListState>(
      builder: (context, state) {
        switch (state) {
          case GeoQuizListLoading():
            return LoadingStateView(title: context.t.learn.geoQuiz.loading);
          case GeoQuizListError(:final message):
            return ErrorStateView(
              title: context.t.learn.geoQuiz.failedToLoad,
              message: message,
              retryLabel: context.t.common.retry,
              onRetry: () =>
                  context.read<GeoQuizListCubit>().open(isProUser: isProUser),
            );
          case GeoQuizListLoaded(:final quizzes):
            if (quizzes.isEmpty) {
              return EmptyStateView(
                title: context.t.learn.geoQuiz.emptyTitle,
                subtitle: context.t.learn.geoQuiz.emptySubtitle,
                icon: Icons.public,
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                const horizontalPadding = 16.0;
                const minimumTileWidth = 156.0;
                final availableWidth =
                    constraints.maxWidth - (horizontalPadding * 2);
                final columnCount =
                    ((availableWidth + spacing) / (minimumTileWidth + spacing))
                        .floor()
                        .clamp(1, 3);
                final tileWidth =
                    (availableWidth - (spacing * (columnCount - 1))) /
                    columnCount;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    16,
                  ),
                  child: Wrap(
                    key: const Key('geoQuizGrid'),
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final quiz in quizzes)
                        SizedBox(
                          width: tileWidth,
                          child: _GeoQuizGridTile(
                            key: ValueKey('geoQuizTile.${quiz.id}'),
                            quiz: quiz,
                            progress: state.progressFor(quiz.id),
                            locked: !isProUser && quiz.isProOnly,
                            onTap: () async {
                              final canOpen = await _canOpenQuiz(
                                context,
                                quiz: quiz,
                                isProUser: isProUser,
                              );
                              if (!canOpen || !context.mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GeoQuizScreen(summary: quiz),
                                ),
                              );
                              if (!context.mounted) return;
                              await context
                                  .read<GeoQuizListCubit>()
                                  .refreshProgress();
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
        }
      },
    );
  }

  Future<bool> _canOpenQuiz(
    BuildContext context, {
    required GeoQuizSummary quiz,
    required bool isProUser,
  }) async {
    if (!quiz.isProOnly || isProUser) return true;

    final connectivityChecker = GetIt.I.isRegistered<ConnectivityChecker>()
        ? GetIt.I<ConnectivityChecker>()
        : const ConnectivityChecker();
    final hasInternet = await connectivityChecker.hasInternetConnectivity();
    if (!context.mounted) return false;
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.learn.upgradeRequiresInternet)),
      );
      return false;
    }

    final result = await context
        .read<SubscriptionCubit>()
        .presentPaywallFromGeoQuiz();
    if (!context.mounted) return false;
    return switch (result) {
      SubscriptionPaywallResult.purchased ||
      SubscriptionPaywallResult.restored => true,
      SubscriptionPaywallResult.error => _showPaywallMessage(
        context,
        context.t.settings.failedOpenPaywall,
      ),
      SubscriptionPaywallResult.notPresented => _showPaywallMessage(
        context,
        context.t.settings.noPaywall,
      ),
      SubscriptionPaywallResult.cancelled => false,
    };
  }

  bool _showPaywallMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    return false;
  }
}

class _GeoQuizGridTile extends StatelessWidget {
  const _GeoQuizGridTile({
    required this.quiz,
    required this.progress,
    required this.locked,
    required this.onTap,
    super.key,
  });

  final GeoQuizSummary quiz;
  final GeoQuizProgress progress;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = DsSemanticColors.success(context);
    final solved = progress.solvedCount.clamp(0, quiz.totalCount).toInt();
    final fraction = quiz.totalCount <= 0 ? 0.0 : solved / quiz.totalCount;
    final isComplete = quiz.totalCount > 0 && solved >= quiz.totalCount;
    final localizedTitle = localizedGeoQuizTitle(context.t, quiz);
    final localizedSubtitle = localizedGeoQuizSubtitle(context.t, quiz);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    locked ? Icons.lock_outline_rounded : Icons.public,
                    color: locked
                        ? DsBrandColors.proAmber
                        : isComplete
                        ? success
                        : theme.colorScheme.primary,
                    size: 22,
                  ),
                  const Spacer(),
                  if (locked)
                    const ProBadge(
                      compact: true,
                      variant: ProBadgeVariant.premiumBlueStripes,
                    )
                  else
                    Text(
                      context.t.learn.geoQuiz.progressCount(
                        solved: solved,
                        total: quiz.totalCount,
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isComplete ? success : theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                localizedTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: fraction.clamp(0.0, 1.0),
                  valueColor: AlwaysStoppedAnimation<Color>(success),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
