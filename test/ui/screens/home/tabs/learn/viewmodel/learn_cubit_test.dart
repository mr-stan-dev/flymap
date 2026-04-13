import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_state.dart';
import 'package:flymap/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/usecase/toggle_learn_article_favorite_use_case.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  test('free user can load and browse premium category article list', () async {
    final repository = _FakeLearnRepository();
    final progressRepository = _InMemoryLearnArticleProgressRepository();
    final cubit = LearnCubit(
      getLearnCategoriesUseCase: GetLearnCategoriesUseCase(
        repository: repository,
      ),
      getLearnCategoryArticlesUseCase: GetLearnCategoryArticlesUseCase(
        repository: repository,
      ),
      getLearnArticleContentUseCase: GetLearnArticleContentUseCase(
        repository: repository,
      ),
      getLearnArticleProgressUseCase: GetLearnArticleProgressUseCase(
        repository: progressRepository,
      ),
      toggleLearnArticleFavoriteUseCase: ToggleLearnArticleFavoriteUseCase(
        repository: progressRepository,
      ),
      markLearnArticleSeenUseCase: MarkLearnArticleSeenUseCase(
        repository: progressRepository,
      ),
      canOpenLearnArticleUseCase: CanOpenLearnArticleUseCase(
        repository: repository,
      ),
      connectivityChecker: _FakeConnectivityChecker(hasInternet: true),
    );
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state, isA<LearnLoaded>());

    final articles = await cubit.loadCategoryArticles(categoryId: 'pro_cat');
    expect(articles.length, 1);
    expect(articles.single.title, 'Pro One');
  });

  test(
    'locked premium article tap returns paywall intent when online',
    () async {
      final repository = _FakeLearnRepository();
      final progressRepository = _InMemoryLearnArticleProgressRepository();
      final cubit = LearnCubit(
        getLearnCategoriesUseCase: GetLearnCategoriesUseCase(
          repository: repository,
        ),
        getLearnCategoryArticlesUseCase: GetLearnCategoryArticlesUseCase(
          repository: repository,
        ),
        getLearnArticleContentUseCase: GetLearnArticleContentUseCase(
          repository: repository,
        ),
        getLearnArticleProgressUseCase: GetLearnArticleProgressUseCase(
          repository: progressRepository,
        ),
        toggleLearnArticleFavoriteUseCase: ToggleLearnArticleFavoriteUseCase(
          repository: progressRepository,
        ),
        markLearnArticleSeenUseCase: MarkLearnArticleSeenUseCase(
          repository: progressRepository,
        ),
        canOpenLearnArticleUseCase: CanOpenLearnArticleUseCase(
          repository: repository,
        ),
        connectivityChecker: _FakeConnectivityChecker(hasInternet: true),
      );
      addTearDown(cubit.close);

      final result = await cubit.onArticleTapped(
        article: repository.proCategory.articles.single,
        isProUser: false,
      );

      expect(result, isA<LearnUpgradeRequired>());
    },
  );

  test(
    'locked premium article tap returns offline explanation when offline',
    () async {
      final repository = _FakeLearnRepository();
      final progressRepository = _InMemoryLearnArticleProgressRepository();
      final cubit = LearnCubit(
        getLearnCategoriesUseCase: GetLearnCategoriesUseCase(
          repository: repository,
        ),
        getLearnCategoryArticlesUseCase: GetLearnCategoryArticlesUseCase(
          repository: repository,
        ),
        getLearnArticleContentUseCase: GetLearnArticleContentUseCase(
          repository: repository,
        ),
        getLearnArticleProgressUseCase: GetLearnArticleProgressUseCase(
          repository: progressRepository,
        ),
        toggleLearnArticleFavoriteUseCase: ToggleLearnArticleFavoriteUseCase(
          repository: progressRepository,
        ),
        markLearnArticleSeenUseCase: MarkLearnArticleSeenUseCase(
          repository: progressRepository,
        ),
        canOpenLearnArticleUseCase: CanOpenLearnArticleUseCase(
          repository: repository,
        ),
        connectivityChecker: _FakeConnectivityChecker(hasInternet: false),
      );
      addTearDown(cubit.close);

      final result = await cubit.onArticleTapped(
        article: repository.proCategory.articles.single,
        isProUser: false,
      );

      expect(result, isA<LearnOfflineUpgradeBlocked>());
    },
  );
}

class _FakeConnectivityChecker extends ConnectivityChecker {
  const _FakeConnectivityChecker({required this.hasInternet});

  final bool hasInternet;

  @override
  Future<bool> hasInternetConnectivity({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    return hasInternet;
  }
}

class _FakeLearnRepository implements LearnRepository {
  _FakeLearnRepository() {
    _categories = [
      LearnCategory(
        id: 'free_cat',
        title: 'Free Cat',
        description: 'Free description',
        imageAssetPath: 'assets/images/learn/categories/free_cat.webp',
        articles: const [
          LearnArticleMeta(
            id: 'f1',
            title: 'Free One',
            categoryId: 'free_cat',
            access: LearnAccess.free,
          ),
        ],
      ),
      LearnCategory(
        id: 'pro_cat',
        title: 'Pro Cat',
        description: 'Pro description',
        imageAssetPath: 'assets/images/learn/categories/pro_cat.webp',
        articles: const [
          LearnArticleMeta(
            id: 'p1',
            title: 'Pro One',
            categoryId: 'pro_cat',
            access: LearnAccess.pro,
          ),
        ],
      ),
    ];
  }

  late final List<LearnCategory> _categories;

  LearnCategory get proCategory =>
      _categories.firstWhere((category) => category.id == 'pro_cat');

  @override
  bool canOpenArticle({
    required LearnAccess articleAccess,
    required bool isProUser,
  }) {
    return articleAccess == LearnAccess.free || isProUser;
  }

  @override
  Future<LearnArticleContent> getArticleContent({
    required String articleId,
  }) async {
    final article = _categories
        .expand((category) => category.articles)
        .firstWhere((item) => item.id == articleId);
    return LearnArticleContent(
      id: article.id,
      title: article.title,
      categoryId: article.categoryId,
      markdown: '# ${article.title}',
    );
  }

  @override
  Future<List<LearnArticleMeta>> getArticles({
    required String categoryId,
  }) async {
    return _categories
        .firstWhere((category) => category.id == categoryId)
        .articles;
  }

  @override
  Future<List<LearnCategory>> getCategories() async {
    return _categories;
  }
}

class _InMemoryLearnArticleProgressRepository
    implements LearnArticleProgressRepository {
  final Map<String, LearnArticleProgress> _state =
      <String, LearnArticleProgress>{};

  @override
  Future<Map<String, LearnArticleProgress>> getByArticleIds(
    Iterable<String> articleIds,
  ) async {
    return <String, LearnArticleProgress>{
      for (final id in articleIds) id: _state[id] ?? LearnArticleProgress.empty,
    };
  }

  @override
  Future<LearnArticleProgress> markSeen(String articleId) async {
    final updated = (_state[articleId] ?? LearnArticleProgress.empty).copyWith(
      isSeen: true,
    );
    _state[articleId] = updated;
    return updated;
  }

  @override
  Future<LearnArticleProgress> toggleFavorite(String articleId) async {
    final current = _state[articleId] ?? LearnArticleProgress.empty;
    final updated = current.copyWith(isFavorite: !current.isFavorite);
    _state[articleId] = updated;
    return updated;
  }
}
