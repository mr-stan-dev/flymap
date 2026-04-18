import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/local/airports_database.dart';
import 'package:flymap/entity/flight.dart';
import 'package:flymap/entity/flight_info.dart';
import 'package:flymap/entity/learn_access.dart';
import 'package:flymap/entity/learn_article_content.dart';
import 'package:flymap/entity/learn_article_meta.dart';
import 'package:flymap/entity/learn_article_progress.dart';
import 'package:flymap/entity/learn_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_repository.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/repository/metric_units_repository.dart';
import 'package:flymap/repository/onboarding_repository.dart';
import 'package:flymap/repository/settings_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/repository/user_flight_prefs_storage.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/ui/screens/home/home_screen.dart';
import 'package:flymap/ui/screens/settings/viewmodel/settings_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flymap/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/usecase/delete_flight_use_case.dart';
import 'package:flymap/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/usecase/toggle_learn_article_favorite_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GetIt.I.reset();
    GetIt.I.registerSingleton<FlightRepository>(_FakeFlightRepository());
    GetIt.I.registerSingleton<DeleteFlightUseCase>(_FakeDeleteFlightUseCase());
    final learnRepository = _FakeLearnRepository();
    GetIt.I.registerSingleton<GetLearnCategoriesUseCase>(
      GetLearnCategoriesUseCase(repository: learnRepository),
    );
    GetIt.I.registerSingleton<GetLearnCategoryArticlesUseCase>(
      GetLearnCategoryArticlesUseCase(repository: learnRepository),
    );
    GetIt.I.registerSingleton<GetLearnArticleContentUseCase>(
      GetLearnArticleContentUseCase(repository: learnRepository),
    );
    final learnProgressRepository = _InMemoryLearnArticleProgressRepository();
    GetIt.I.registerSingleton<GetLearnArticleProgressUseCase>(
      GetLearnArticleProgressUseCase(repository: learnProgressRepository),
    );
    GetIt.I.registerSingleton<ToggleLearnArticleFavoriteUseCase>(
      ToggleLearnArticleFavoriteUseCase(repository: learnProgressRepository),
    );
    GetIt.I.registerSingleton<MarkLearnArticleSeenUseCase>(
      MarkLearnArticleSeenUseCase(repository: learnProgressRepository),
    );
    GetIt.I.registerSingleton<CanOpenLearnArticleUseCase>(
      CanOpenLearnArticleUseCase(repository: learnRepository),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('defaults to Flights tab with dynamic app bar title', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    expect(_findAppBarTitle('Flights'), findsOneWidget);
    expect(find.text('New flight'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      0,
    );
  });

  testWidgets('switches to Learn tab and keeps app stable', (tester) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    await tester.tap(find.text('Learn'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_findAppBarTitle('Learn'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      1,
    );
  });

  testWidgets('switches to Settings tab and renders settings content', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await _pumpForInitialLoad(tester);

    await tester.tap(find.text('Settings'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(_findAppBarTitle('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );
  });

  testWidgets('supports preselecting Settings tab from constructor', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(initialTab: HomeRootTab.settings));
    await _pumpForInitialLoad(tester);

    expect(_findAppBarTitle('Settings'), findsOneWidget);
    expect(
      tester
          .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
          .currentIndex,
      2,
    );
  });
}

Widget _testApp({HomeRootTab initialTab = HomeRootTab.flights}) {
  return TranslationProvider(
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(
            repository: SettingsRepository(),
            unitsRepository: MetricUnitsRepository(),
            onboardingRepository: OnboardingRepository(
              prefsStorage: UserFlightPrefsStorage(),
            ),
            airportsDatabase: AirportsDatabase.test(seedAirports: const []),
          )..load(),
        ),
        BlocProvider(
          create: (_) => SubscriptionCubit(
            repository: _FakeSubscriptionRepository(),
            analytics: const _FakeAppAnalytics(),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomeScreen(initialTab: initialTab),
      ),
    ),
  );
}

Finder _findAppBarTitle(String title) {
  return find.descendant(of: find.byType(AppBar), matching: find.text(title));
}

Future<void> _pumpForInitialLoad(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

class _FakeFlightRepository implements FlightRepository {
  @override
  Future<List<Flight>> getAllFlights() async => const [];

  @override
  Future<Flight?> getFlightById(String flightId) async => null;

  @override
  Future<int> getTotalDownloadedMaps() async => 0;

  @override
  Future<int> getTotalFlights() async => 0;

  @override
  Future<int> getTotalMapSize() async => 0;

  @override
  Future<String> insertFlight(Flight flight) async => 'flight-id';

  @override
  Future<String> saveOrUpdateFlight(Flight flight) async => 'flight-id';

  @override
  Future<bool> updateFlightInfo({
    required String flightId,
    required FlightInfo info,
  }) async => true;
}

class _FakeDeleteFlightUseCase implements DeleteFlightUseCase {
  @override
  Future<bool> call(String flightId) async => true;
}

class _FakeSubscriptionRepository implements SubscriptionRepository {
  _FakeSubscriptionRepository()
    : _currentStatus = SubscriptionStatus(
        isPro: false,
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
