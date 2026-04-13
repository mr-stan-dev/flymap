import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_article_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_article_tile.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_state.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_state.dart';

class LearnCategoryScreen extends StatefulWidget {
  const LearnCategoryScreen({required this.category, super.key});

  final LearnCategory category;

  @override
  State<LearnCategoryScreen> createState() => _LearnCategoryScreenState();
}

class _LearnCategoryScreenState extends State<LearnCategoryScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<LearnArticleMeta> _articles = const <LearnArticleMeta>[];
  Map<String, LearnArticleProgress> _progressByArticleId =
      const <String, LearnArticleProgress>{};
  final Set<String> _favoriteInFlight = <String>{};

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.title)),
      body: SafeArea(
        child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
          builder: (context, subscriptionState) {
            final isProUser = subscriptionState.isPro;
            if (_isLoading) {
              return LoadingStateView(title: context.t.learn.loadingArticles);
            }
            if (_hasError) {
              return ErrorStateView(
                title: context.t.learn.failedToLoadArticles,
                message: context.t.learn.failedToLoadArticles,
                retryLabel: context.t.common.retry,
                onRetry: _reloadArticles,
              );
            }
            if (_articles.isEmpty) {
              return EmptyStateView(
                title: context.t.learn.emptyArticlesTitle,
                subtitle: context.t.learn.emptyArticlesSubtitle,
                icon: Icons.menu_book_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemBuilder: (context, index) {
                final article = _articles[index];
                final progress =
                    _progressByArticleId[article.id] ??
                    LearnArticleProgress.empty;
                final isLockedArticle = !isProUser && article.isProOnly;
                return LearnArticleTile(
                  article: article,
                  locked: isLockedArticle,
                  isSeen: progress.isSeen,
                  isFavorite: progress.isFavorite,
                  favoriteInFlight: _favoriteInFlight.contains(article.id),
                  onFavoriteTap: () => _toggleFavorite(article.id),
                  onTap: () async {
                    await _handleArticleTap(
                      context,
                      article: article,
                      isProUser: isProUser,
                    );
                  },
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _articles.length,
            );
          },
        ),
      ),
    );
  }

  void _reloadArticles() {
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final cubit = context.read<LearnCubit>();
    try {
      final articles = await cubit.loadCategoryArticles(
        categoryId: widget.category.id,
      );
      final progressByArticleId = await cubit.loadArticleProgress(
        articleIds: articles.map((article) => article.id),
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = false;
        _articles = articles;
        _progressByArticleId = progressByArticleId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _toggleFavorite(String articleId) async {
    if (_favoriteInFlight.contains(articleId)) return;
    setState(() => _favoriteInFlight.add(articleId));
    final updated = await context.read<LearnCubit>().toggleArticleFavorite(
      articleId: articleId,
    );
    if (!mounted) return;
    setState(() {
      _favoriteInFlight.remove(articleId);
      if (updated != null) {
        _progressByArticleId = <String, LearnArticleProgress>{
          ..._progressByArticleId,
          articleId: updated,
        };
      }
    });
  }

  Future<void> _handleArticleTap(
    BuildContext context, {
    required LearnArticleMeta article,
    required bool isProUser,
  }) async {
    final cubit = context.read<LearnCubit>();
    var result = await cubit.onArticleTapped(
      article: article,
      isProUser: isProUser,
    );
    if (!context.mounted) return;

    if (result is LearnUpgradeRequired) {
      final paywallResult = await context
          .read<SubscriptionCubit>()
          .presentPaywallFromLearn();
      if (!context.mounted) return;

      switch (paywallResult) {
        case SubscriptionPaywallResult.purchased:
        case SubscriptionPaywallResult.restored:
          result = await cubit.onArticleTapped(
            article: article,
            isProUser: true,
          );
          if (!context.mounted) return;
          break;
        case SubscriptionPaywallResult.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.t.settings.failedOpenPaywall)),
          );
          return;
        case SubscriptionPaywallResult.notPresented:
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.t.settings.noPaywall)));
          return;
        case SubscriptionPaywallResult.cancelled:
          return;
      }
    }

    switch (result) {
      case LearnOpenArticle(:final article):
        final seenProgress = await cubit.markArticleSeen(articleId: article.id);
        if (!context.mounted) return;
        if (seenProgress != null) {
          setState(() {
            _progressByArticleId = <String, LearnArticleProgress>{
              ..._progressByArticleId,
              article.id: seenProgress,
            };
          });
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LearnArticleScreen(article: article),
          ),
        );
        return;
      case LearnOfflineUpgradeBlocked(:final message):
      case LearnOpenArticleFailed(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        return;
      case LearnUpgradeRequired():
        // Handled above.
        return;
    }
  }
}
