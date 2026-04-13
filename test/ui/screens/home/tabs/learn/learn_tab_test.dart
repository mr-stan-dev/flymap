import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_tab.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
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

  testWidgets('does not show PRO badge on category cards', (tester) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pro Cat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Pro Cat'), findsOneWidget);
    expect(find.byType(LearnTab), findsOneWidget);
    expect(find.text('PRO'), findsNothing);
  });

  testWidgets('free user can browse premium category article titles', (
    tester,
  ) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pro Cat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro Cat'));
    await tester.pumpAndSettle();

    expect(find.text('Pro One'), findsOneWidget);
    expect(
      find.text(
        'You can browse these article titles now. Unlock reading with Flymap Pro.',
      ),
      findsNothing,
    );
  });

  testWidgets('pro user can open premium category article', (tester) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: true, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Pro Cat'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pro Cat'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pro One'));
    await tester.pumpAndSettle();

    expect(find.text('Pro One'), findsWidgets);
    expect(find.byType(Scaffold), findsWidgets);
  });

  testWidgets('article favorite star toggles in category list', (tester) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Free Cat'));
    await tester.pumpAndSettle();

    final emptyStar = find.byIcon(Icons.star_outline_rounded);
    expect(emptyStar, findsOneWidget);

    await tester.tap(emptyStar);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });
}

LearnCubit _buildLearnCubit(_FakeLearnRepository repository) {
  final progressRepository = _InMemoryLearnArticleProgressRepository();
  return LearnCubit(
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
  );
}

Widget _testApp({required bool isProUser, required Widget child}) {
  return TranslationProvider(
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SubscriptionCubit(
            repository: _FakeSubscriptionRepository(isProUser: isProUser),
            analytics: const _FakeAppAnalytics(),
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: child),
      ),
    ),
  );
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
      markdown: '# ${article.title}\n\nArticle content.',
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

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository({required bool isProUser})
    : _currentStatus = SubscriptionStatus(
        isPro: isProUser,
        entitlementId: 'pro',
        lastUpdatedAt: DateTime.now(),
      );

  final SubscriptionStatus _currentStatus;

  @override
  SubscriptionStatus get currentStatus => _currentStatus;

  @override
  Stream<SubscriptionStatus> get statusStream =>
      const Stream<SubscriptionStatus>.empty();

  @override
  Future<void> close() async {}

  @override
  Future<List<SubscriptionProduct>> getProducts() async =>
      const <SubscriptionProduct>[];

  @override
  Future<SubscriptionStatus> initialize() async => _currentStatus;

  @override
  Future<SubscriptionPaywallResult> presentPaywallIfNeeded() async =>
      SubscriptionPaywallResult.notPresented;

  @override
  Future<void> presentCustomerCenter() async {}

  @override
  Future<SubscriptionStatus> purchasePackage({
    required String packageId,
  }) async => _currentStatus;

  @override
  Future<SubscriptionStatus> refresh() async => _currentStatus;

  @override
  Future<SubscriptionStatus> restorePurchases() async => _currentStatus;
}

class _FakeAppAnalytics implements AppAnalytics {
  const _FakeAppAnalytics();

  @override
  Future<void> log(AnalyticsEvent event) async {}

  @override
  Future<void> setGlobalContext({
    required String appVersion,
    required String buildNumber,
    required String platform,
    required String appEnv,
  }) async {}

  @override
  Future<void> setSubscriptionContext({required bool isPro}) async {}
}
