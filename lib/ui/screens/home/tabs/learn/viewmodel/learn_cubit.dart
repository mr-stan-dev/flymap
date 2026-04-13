import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/logger.dart';
import 'package:flymap/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/usecase/toggle_learn_article_favorite_use_case.dart';
import 'package:get_it/get_it.dart';

import 'learn_state.dart';

class LearnCubit extends Cubit<LearnState> {
  LearnCubit({
    GetLearnCategoriesUseCase? getLearnCategoriesUseCase,
    GetLearnCategoryArticlesUseCase? getLearnCategoryArticlesUseCase,
    GetLearnArticleContentUseCase? getLearnArticleContentUseCase,
    GetLearnArticleProgressUseCase? getLearnArticleProgressUseCase,
    ToggleLearnArticleFavoriteUseCase? toggleLearnArticleFavoriteUseCase,
    MarkLearnArticleSeenUseCase? markLearnArticleSeenUseCase,
    CanOpenLearnArticleUseCase? canOpenLearnArticleUseCase,
    ConnectivityChecker? connectivityChecker,
  }) : _getLearnCategoriesUseCase =
           getLearnCategoriesUseCase ?? GetIt.I<GetLearnCategoriesUseCase>(),
       _getLearnCategoryArticlesUseCase =
           getLearnCategoryArticlesUseCase ??
           GetIt.I<GetLearnCategoryArticlesUseCase>(),
       _getLearnArticleContentUseCase =
           getLearnArticleContentUseCase ??
           GetIt.I<GetLearnArticleContentUseCase>(),
       _getLearnArticleProgressUseCase =
           getLearnArticleProgressUseCase ??
           GetIt.I<GetLearnArticleProgressUseCase>(),
       _toggleLearnArticleFavoriteUseCase =
           toggleLearnArticleFavoriteUseCase ??
           GetIt.I<ToggleLearnArticleFavoriteUseCase>(),
       _markLearnArticleSeenUseCase =
           markLearnArticleSeenUseCase ??
           GetIt.I<MarkLearnArticleSeenUseCase>(),
       _canOpenLearnArticleUseCase =
           canOpenLearnArticleUseCase ?? GetIt.I<CanOpenLearnArticleUseCase>(),
       _connectivityChecker =
           connectivityChecker ?? const ConnectivityChecker(),
       super(const LearnLoading());

  final GetLearnCategoriesUseCase _getLearnCategoriesUseCase;
  final GetLearnCategoryArticlesUseCase _getLearnCategoryArticlesUseCase;
  final GetLearnArticleContentUseCase _getLearnArticleContentUseCase;
  final GetLearnArticleProgressUseCase _getLearnArticleProgressUseCase;
  final ToggleLearnArticleFavoriteUseCase _toggleLearnArticleFavoriteUseCase;
  final MarkLearnArticleSeenUseCase _markLearnArticleSeenUseCase;
  final CanOpenLearnArticleUseCase _canOpenLearnArticleUseCase;
  final ConnectivityChecker _connectivityChecker;
  final Logger _logger = const Logger('LearnCubit');

  Future<void> load() async {
    emit(const LearnLoading());
    try {
      final categories = await _getLearnCategoriesUseCase();
      emit(LearnLoaded(categories: categories));
    } catch (e) {
      _logger.error('Failed to load learn categories: $e');
      emit(LearnError(message: t.learn.failedToLoadCategories));
    }
  }

  Future<void> retry() async {
    await load();
  }

  Future<List<LearnArticleMeta>> loadCategoryArticles({
    required String categoryId,
  }) async {
    try {
      return await _getLearnCategoryArticlesUseCase(categoryId: categoryId);
    } catch (e) {
      _logger.error('Failed to load learn articles for "$categoryId": $e');
      rethrow;
    }
  }

  Future<Map<String, LearnArticleProgress>> loadArticleProgress({
    required Iterable<String> articleIds,
  }) async {
    try {
      return await _getLearnArticleProgressUseCase(articleIds: articleIds);
    } catch (e) {
      _logger.error('Failed to load learn article progress: $e');
      return <String, LearnArticleProgress>{};
    }
  }

  Future<LearnArticleProgress?> toggleArticleFavorite({
    required String articleId,
  }) async {
    try {
      return await _toggleLearnArticleFavoriteUseCase(articleId: articleId);
    } catch (e) {
      _logger.error('Failed to toggle favorite for "$articleId": $e');
      return null;
    }
  }

  Future<LearnArticleProgress?> markArticleSeen({
    required String articleId,
  }) async {
    try {
      return await _markLearnArticleSeenUseCase(articleId: articleId);
    } catch (e) {
      _logger.error('Failed to mark article as seen for "$articleId": $e');
      return null;
    }
  }

  Future<LearnArticleTapResult> onArticleTapped({
    required LearnArticleMeta article,
    required bool isProUser,
  }) async {
    final canOpen = _canOpenLearnArticleUseCase(
      articleAccess: article.access,
      isProUser: isProUser,
    );
    if (!canOpen) {
      final hasInternet = await _connectivityChecker.hasInternetConnectivity();
      if (hasInternet) {
        return const LearnUpgradeRequired();
      }
      return LearnOfflineUpgradeBlocked(
        message: t.learn.upgradeRequiresInternet,
      );
    }

    try {
      final content = await _getLearnArticleContentUseCase(
        articleId: article.id,
      );
      return LearnOpenArticle(content);
    } catch (e) {
      _logger.error('Failed to open learn article "${article.id}": $e');
      return LearnOpenArticleFailed(message: t.learn.failedToLoadArticle);
    }
  }
}
