import 'dart:async';

import 'package:country_flags/country_flags.dart' as country_flags;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/analytics/app_analytics.dart';
import 'package:flymap/data/network/connectivity_checker.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';
import 'package:flymap/domain/entity/learn_access.dart';
import 'package:flymap/domain/entity/route_region_type.dart';
import 'package:flymap/domain/entity/learn_article_content.dart';
import 'package:flymap/domain/entity/learn_article_meta.dart';
import 'package:flymap/domain/entity/learn_article_progress.dart';
import 'package:flymap/domain/entity/learn_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/flight_unlock_repository.dart';
import 'package:flymap/repository/geo_quiz_progress_repository.dart';
import 'package:flymap/repository/geo_quiz_repository.dart';
import 'package:flymap/repository/learn_article_progress_repository.dart';
import 'package:flymap/repository/learn_repository.dart';
import 'package:flymap/repository/subscription_repository.dart';
import 'package:flymap/subscription/flight_unlock_product.dart';
import 'package:flymap/subscription/flight_unlock_purchase_result.dart';
import 'package:flymap/subscription/subscription_paywall_result.dart';
import 'package:flymap/subscription/subscription_product.dart';
import 'package:flymap/subscription/subscription_status.dart';
import 'package:flymap/router/app_router.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/geo_quiz_entry_card.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_article_screen.dart';
import 'package:flymap/ui/screens/home/tabs/learn/learn_tab.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/geo_quiz/viewmodel/geo_quiz_list_cubit.dart';
import 'package:flymap/ui/screens/home/tabs/learn/viewmodel/learn_cubit.dart';
import 'package:flymap/ui/screens/subscription/viewmodel/subscription_cubit.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flymap/ui/widgets/pro_widgets.dart';
import 'package:flymap/domain/usecase/can_open_learn_article_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_article_content_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_article_progress_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_categories_use_case.dart';
import 'package:flymap/domain/usecase/get_learn_category_articles_use_case.dart';
import 'package:flymap/domain/usecase/mark_learn_article_seen_use_case.dart';
import 'package:flymap/domain/usecase/toggle_learn_article_favorite_use_case.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final getIt = GetIt.I;
    if (getIt.isRegistered<GeoQuizRepository>()) {
      getIt.unregister<GeoQuizRepository>();
    }
    getIt.registerLazySingleton<GeoQuizRepository>(
      () => _FakeGeoQuizRepository(),
    );
    if (getIt.isRegistered<GeoQuizProgressRepository>()) {
      getIt.unregister<GeoQuizProgressRepository>();
    }
    getIt.registerLazySingleton<GeoQuizProgressRepository>(
      () => SharedPrefsGeoQuizProgressRepository(),
    );
    if (getIt.isRegistered<ConnectivityChecker>()) {
      getIt.unregister<ConnectivityChecker>();
    }
    getIt.registerSingleton<ConnectivityChecker>(
      const _FakeConnectivityChecker(hasInternet: true),
    );
    if (getIt.isRegistered<AppAnalytics>()) {
      getIt.unregister<AppAnalytics>();
    }
    getIt.registerSingleton<AppAnalytics>(_FakeAppAnalytics());
    if (getIt.isRegistered<GeoQuizListCubit>()) {
      getIt.unregister<GeoQuizListCubit>();
    }
    getIt.registerFactoryParam<GeoQuizListCubit, String, Object?>(
      (collectionId, _) => GeoQuizListCubit(
        collectionId: collectionId,
        repository: getIt.get(),
        progressRepository: getIt.get(),
        analytics: getIt.get(),
      ),
    );
    if (getIt.isRegistered<GeoQuizCubit>()) {
      getIt.unregister<GeoQuizCubit>();
    }
    getIt.registerFactoryParam<GeoQuizCubit, GeoQuizSummary, bool>(
      (summary, isProUser) => GeoQuizCubit(
        summary: summary,
        repository: getIt.get(),
        progressRepository: getIt.get(),
        languageCodeProvider: () => 'en',
        analytics: getIt.get(),
        isProUser: isProUser,
        nowProvider: DateTime.now,
      ),
    );
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

  testWidgets('shows Countries on map in Quizzes before learn categories', (
    tester,
  ) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.text('Geography'), findsOneWidget);
    expect(find.text('Countries on map'), findsOneWidget);
    expect(find.text('Start practicing'), findsNothing);
    expect(find.text('Free Cat'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Countries on map')).dy,
      lessThan(tester.getTopLeft(find.text('Geography')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Geography')).dy,
      lessThan(tester.getTopLeft(find.text('Free Cat')).dy),
    );
    expect(
      tester.getTopLeft(find.byKey(CountriesQuizEntryCard.imageKey)).dx,
      lessThan(tester.getTopLeft(find.text('Countries on map')).dx),
    );
  });

  testWidgets('can show NEW badge on Geo Quiz card', (tester) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(
        isProUser: false,
        child: LearnTab(cubit: learnCubit, showGeoQuizNewBadge: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('learn.geo_quiz.new_badge')), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('shows quiz progress and section titles', (tester) async {
    await GetIt.I<GeoQuizProgressRepository>().markSolved(
      quizId: 'countries_africa',
      regionId: 'AO',
    );
    await GetIt.I<GeoQuizProgressRepository>().markSolved(
      quizId: 'countries_europe',
      regionId: 'FR',
    );
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CountriesQuizEntryCard.finishedMetricKey),
      findsOneWidget,
    );
    expect(
      find.byKey(CountriesQuizEntryCard.inProgressMetricKey),
      findsOneWidget,
    );
    expect(find.text('1 finished'), findsOneWidget);
    expect(find.text('1 in progress'), findsOneWidget);
    expect(find.text('Quizzes'), findsOneWidget);
    expect(find.text('Articles'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Articles')).dy,
      lessThan(tester.getTopLeft(find.text('Free Cat')).dy),
    );
  });

  testWidgets('shows all completed when every quiz is finished', (
    tester,
  ) async {
    final progressRepository = GetIt.I<GeoQuizProgressRepository>();
    for (final regionId in const ['AO']) {
      await progressRepository.markSolved(
        quizId: 'countries_africa',
        regionId: regionId,
      );
    }
    for (final regionId in const ['FR', 'DE']) {
      await progressRepository.markSolved(
        quizId: 'countries_europe',
        regionId: regionId,
      );
    }
    for (final regionId in const ['AO', 'FR', 'DE']) {
      await progressRepository.markSolved(
        quizId: 'countries_world',
        regionId: regionId,
      );
    }

    final learnCubit = _buildLearnCubit(_FakeLearnRepository());
    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(CountriesQuizEntryCard.allCompletedMetricKey),
      findsOneWidget,
    );
    expect(find.text('All completed'), findsOneWidget);
    expect(
      find.byKey(CountriesQuizEntryCard.inProgressMetricKey),
      findsNothing,
    );
  });

  testWidgets('hides NEW badge on Geo Quiz card by default', (tester) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('learn.geo_quiz.new_badge')), findsNothing);
  });

  testWidgets('opens Geo Quiz list and quiz screen from Learn tab', (
    tester,
  ) async {
    final analytics = _FakeAppAnalytics();
    GetIt.I.unregister<AppAnalytics>();
    GetIt.I.registerSingleton<AppAnalytics>(analytics);
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Geography'));
    await tester.pumpAndSettle();

    expect(find.text('Geography'), findsOneWidget);
    expect(find.byKey(const Key('geoQuizGrid')), findsOneWidget);
    final seasTile = find.byKey(const ValueKey('geoQuizTile.geography_seas'));
    final mountainTile = find.byKey(
      const ValueKey('geoQuizTile.geography_mountain_ranges'),
    );
    final lakesTile = find.byKey(const ValueKey('geoQuizTile.geography_lakes'));
    final islandsTile = find.byKey(
      const ValueKey('geoQuizTile.geography_islands'),
    );
    final otherTile = find.byKey(const ValueKey('geoQuizTile.geography_other'));
    expect(seasTile, findsOneWidget);
    expect(mountainTile, findsOneWidget);
    expect(lakesTile, findsOneWidget);
    expect(islandsTile, findsOneWidget);
    expect(otherTile, findsOneWidget);
    expect(find.byType(ProBadge), findsNWidgets(3));

    final seasOffset = tester.getTopLeft(seasTile);
    final mountainOffset = tester.getTopLeft(mountainTile);
    final lakesOffset = tester.getTopLeft(lakesTile);
    final islandsOffset = tester.getTopLeft(islandsTile);
    final otherOffset = tester.getTopLeft(otherTile);
    expect(seasOffset.dy, lessThanOrEqualTo(mountainOffset.dy));
    expect(mountainOffset.dy, lessThanOrEqualTo(lakesOffset.dy));
    expect(lakesOffset.dy, lessThanOrEqualTo(islandsOffset.dy));
    expect(islandsOffset.dy, lessThanOrEqualTo(otherOffset.dy));
    if (seasOffset.dy == mountainOffset.dy) {
      expect(seasOffset.dx, lessThan(mountainOffset.dx));
    }
    if (mountainOffset.dy == lakesOffset.dy) {
      expect(mountainOffset.dx, lessThan(lakesOffset.dx));
    }
    if (lakesOffset.dy == islandsOffset.dy) {
      expect(lakesOffset.dx, lessThan(islandsOffset.dx));
    }
    if (islandsOffset.dy == otherOffset.dy) {
      expect(islandsOffset.dx, lessThan(otherOffset.dx));
    }

    await tester.tap(seasTile);
    await tester.pumpAndSettle();
    expect(find.text('Seas'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Countries on map'));
    await tester.pumpAndSettle();

    expect(find.text('Countries on map'), findsOneWidget);
    expect(find.byKey(const Key('geoQuizGrid')), findsOneWidget);
    expect(find.text('Africa'), findsOneWidget);
    expect(find.byType(ProBadge), findsNWidgets(2));
    final listOpenedEvents = analytics.logged
        .whereType<GeoQuizListOpenedEvent>()
        .toList();
    expect(listOpenedEvents, hasLength(2));
    final listOpened = listOpenedEvents.last;
    expect(listOpened.quizCount, 3);
    expect(listOpened.isProUser, isFalse);

    await tester.tap(find.text('Europe'));
    await tester.pump();
    for (var i = 0; i < 30 && find.byType(TextField).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('locked quiz shows offline upgrade message', (tester) async {
    GetIt.I.unregister<ConnectivityChecker>();
    GetIt.I.registerSingleton<ConnectivityChecker>(
      const _FakeConnectivityChecker(hasInternet: false),
    );
    final learnCubit = _buildLearnCubit(_FakeLearnRepository());

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Countries on map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('World'));
    await tester.pumpAndSettle();

    expect(find.text(t.learn.upgradeRequiresInternet), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Pro user can open locked quiz', (tester) async {
    final learnCubit = _buildLearnCubit(_FakeLearnRepository());

    await tester.pumpWidget(
      _testApp(isProUser: true, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Countries on map'));
    await tester.pumpAndSettle();

    expect(find.byType(ProBadge), findsNothing);
    await tester.tap(find.text('World'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('correct answer countdown can be paused and resumed', (
    tester,
  ) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Countries on map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();

    final answer = find.text('France').evaluate().isNotEmpty
        ? 'France'
        : 'Germany';
    await tester.enterText(find.byType(TextField), answer.substring(0, 2));
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, answer));
    await tester.pump();

    expect(find.byKey(const Key('geoQuizCorrectOverlay')), findsOneWidget);
    await tester.tap(find.byKey(const Key('geoQuizCorrectCountdownToggle')));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const Key('geoQuizCorrectOverlay')), findsOneWidget);

    await tester.tap(find.byKey(const Key('geoQuizCorrectCountdownToggle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('geoQuizCorrectOverlay')), findsNothing);
  });

  testWidgets('final correct answer waits for Finish', (tester) async {
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository);

    await tester.pumpWidget(
      _testApp(isProUser: true, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Countries on map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Africa'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'An');
    await tester.pump();
    await tester.tap(find.widgetWithText(ActionChip, 'Angola'));
    await tester.pump();

    expect(find.byKey(const Key('geoQuizCorrectOverlay')), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(const Key('geoQuizCorrectOverlay')), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Quiz complete'), findsOneWidget);
  });

  testWidgets('country suggestions show flags and hint dialog opens', (
    tester,
  ) async {
    final learnCubit = _buildLearnCubit(_FakeLearnRepository());

    await tester.pumpWidget(
      _testApp(isProUser: false, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Countries on map'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Europe'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'fr');
    await tester.pump();

    final franceChip = find.widgetWithText(ActionChip, 'France');
    expect(franceChip, findsOneWidget);
    expect(
      find.descendant(
        of: franceChip,
        matching: find.byWidgetPredicate(
          (widget) => widget is country_flags.CountryFlag,
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('geoQuizHintButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('geoQuizHintDialog')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geoQuizHintTile.0')).first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('geoQuizHintDialog')), findsOneWidget);
  });

  testWidgets('geography suggestions show region icons', (tester) async {
    final learnCubit = _buildLearnCubit(_FakeLearnRepository());

    await tester.pumpWidget(
      _testApp(isProUser: true, child: LearnTab(cubit: learnCubit)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Geography'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('geoQuizTile.geography_seas')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'med');
    await tester.pump();

    final seaChip = find.widgetWithText(ActionChip, 'Mediterranean Sea');
    expect(seaChip, findsOneWidget);
    expect(
      find.descendant(
        of: seaChip,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Image) return false;
          final provider = widget.image;
          return provider is AssetImage &&
              provider.assetName == RouteRegionType.sea.assetImagePath;
        }),
      ),
      findsOneWidget,
    );
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

    await tester.ensureVisible(find.text('Free Cat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Free Cat'));
    await tester.pumpAndSettle();

    final emptyStar = find.byIcon(Icons.star_outline_rounded);
    expect(emptyStar, findsOneWidget);

    await tester.tap(emptyStar);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('logs learn category and article opens', (tester) async {
    final analytics = _FakeAppAnalytics();
    final learnRepository = _FakeLearnRepository();
    final learnCubit = _buildLearnCubit(learnRepository, analytics: analytics);

    await tester.pumpWidget(
      _testApp(
        isProUser: false,
        analytics: analytics,
        child: LearnTab(cubit: learnCubit),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Free Cat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Free Cat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Free One'));
    await tester.pumpAndSettle();

    expect(
      analytics.logged.whereType<FirebaseAnalyticsEvent>().map(
        (event) => event.firebaseEventName,
      ),
      containsAll(<String>['learn_category_opened', 'learn_article_opened']),
    );
    expect(
      analytics.logged
          .whereType<FirebaseAnalyticsEvent>()
          .firstWhere(
            (event) => event.firebaseEventName == 'learn_category_opened',
          )
          .firebaseParameters,
      <String, Object>{'category_id': 'free_cat', 'article_count': 1},
    );
    expect(
      analytics.logged
          .whereType<FirebaseAnalyticsEvent>()
          .firstWhere(
            (event) => event.firebaseEventName == 'learn_article_opened',
          )
          .firebaseParameters,
      <String, Object>{
        'article_id': 'f1',
        'category_id': 'free_cat',
        'access': 'free',
        'is_pro_user': false,
      },
    );
  });
}

LearnCubit _buildLearnCubit(
  _FakeLearnRepository repository, {
  AppAnalytics? analytics,
}) {
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
    analytics: analytics,
  );
}

Widget _testApp({
  required bool isProUser,
  required Widget child,
  _FakeAppAnalytics? analytics,
}) {
  final appAnalytics = analytics ?? _FakeAppAnalytics();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: AppRouter.learnArticleRoute,
        builder: (context, state) {
          return LearnArticleScreen(
            article: state.extra as LearnArticleContent,
          );
        },
      ),
    ],
  );
  return TranslationProvider(
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SubscriptionCubit(
            repository: _FakeSubscriptionRepository(isProUser: isProUser),
            flightUnlockRepository: _FakeFlightUnlockRepository(),
            analytics: appAnalytics,
          )..initialize(),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
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

class _FakeFlightUnlockRepository implements FlightUnlockRepository {
  @override
  Stream<int> get balanceStream => const Stream<int>.empty();

  @override
  int get currentUnusedUnlockCount => 0;

  @override
  Future<void> close() async {}

  @override
  Future<int> consumeUnlock() async => 0;

  @override
  Future<FlightUnlockProduct?> getUnlockProduct() async => null;

  @override
  Future<int> initialize() async => 0;

  @override
  Future<FlightUnlockPurchaseResult> purchaseUnlock() async =>
      const FlightUnlockPurchaseResult.cancelled();

  @override
  Future<int> restoreUnlock() async => 0;
}

class _FakeGeoQuizRepository implements GeoQuizRepository {
  static const _africaSummary = GeoQuizSummary(
    id: 'countries_africa',
    collectionId: 'countries',
    title: 'Africa',
    subtitle: 'Countries',
    totalCount: 1,
    access: LearnAccess.pro,
  );
  static const _europeSummary = GeoQuizSummary(
    id: 'countries_europe',
    collectionId: 'countries',
    title: 'Europe',
    subtitle: 'Countries',
    totalCount: 2,
  );
  static const _worldSummary = GeoQuizSummary(
    id: 'countries_world',
    collectionId: 'countries',
    title: 'World',
    subtitle: 'Countries',
    totalCount: 3,
    access: LearnAccess.pro,
  );
  static const _seasSummary = GeoQuizSummary(
    id: 'geography_seas',
    collectionId: 'geography',
    title: 'Seas',
    subtitle: 'Seas',
    totalCount: 1,
    iconName: 'waves',
  );
  static const _mountainRangesSummary = GeoQuizSummary(
    id: 'geography_mountain_ranges',
    collectionId: 'geography',
    title: 'Mountain ranges',
    subtitle: 'Mountain ranges',
    totalCount: 1,
    iconName: 'terrain',
  );
  static const _lakesSummary = GeoQuizSummary(
    id: 'geography_lakes',
    collectionId: 'geography',
    title: 'Lakes',
    subtitle: 'Lakes',
    totalCount: 1,
    iconName: 'water',
    access: LearnAccess.pro,
  );
  static const _islandsSummary = GeoQuizSummary(
    id: 'geography_islands',
    collectionId: 'geography',
    title: 'Islands',
    subtitle: 'Islands',
    totalCount: 1,
    iconName: 'landscape',
    access: LearnAccess.pro,
  );
  static const _otherSummary = GeoQuizSummary(
    id: 'geography_other',
    collectionId: 'geography',
    title: 'Other',
    subtitle: 'Bays, straits, gulfs, deserts, and more',
    totalCount: 1,
    iconName: 'explore',
    access: LearnAccess.pro,
  );

  @override
  Future<List<GeoQuizSummary>> getQuizzes({
    required String collectionId,
  }) async {
    return switch (collectionId) {
      'countries' => const [_africaSummary, _europeSummary, _worldSummary],
      'geography' => const [
        _seasSummary,
        _mountainRangesSummary,
        _lakesSummary,
        _islandsSummary,
        _otherSummary,
      ],
      _ => const [],
    };
  }

  @override
  Future<List<GeoQuizRegion>> getRegions({required String quizId}) async {
    return switch (quizId) {
      'countries_europe' => const [
        GeoQuizRegion(id: 'FR', countryCode: 'FR', names: {'en': 'France'}),
        GeoQuizRegion(id: 'DE', countryCode: 'DE', names: {'en': 'Germany'}),
      ],
      'countries_world' => const [
        GeoQuizRegion(id: 'AO', countryCode: 'AO', names: {'en': 'Angola'}),
        GeoQuizRegion(id: 'FR', countryCode: 'FR', names: {'en': 'France'}),
        GeoQuizRegion(id: 'DE', countryCode: 'DE', names: {'en': 'Germany'}),
      ],
      'geography_seas' => const [
        GeoQuizRegion(
          id: 'sea:med',
          names: {'en': 'Mediterranean Sea'},
          regionType: 'sea',
        ),
      ],
      'geography_mountain_ranges' => const [
        GeoQuizRegion(id: 'range:alps', names: {'en': 'Alps'}),
      ],
      'geography_lakes' => const [
        GeoQuizRegion(id: 'lake:baikal', names: {'en': 'Lake Baikal'}),
      ],
      'geography_islands' => const [
        GeoQuizRegion(id: 'island:madagascar', names: {'en': 'Madagascar'}),
      ],
      'geography_other' => const [
        GeoQuizRegion(
          id: 'bay:bengal',
          names: {'en': 'Bay of Bengal'},
          regionType: 'bay',
        ),
      ],
      _ => const [
        GeoQuizRegion(id: 'AO', countryCode: 'AO', names: {'en': 'Angola'}),
      ],
    };
  }

  @override
  Future<String?> getRegionDescription({
    required String quizId,
    required String regionId,
    required String languageCode,
  }) async {
    return null;
  }
}

class _FakeConnectivityChecker extends ConnectivityChecker {
  const _FakeConnectivityChecker({required this.hasInternet});

  final bool hasInternet;

  @override
  Future<bool> hasInternetConnectivity({
    Duration timeout = const Duration(seconds: 2),
  }) async => hasInternet;
}

class _FakeAppAnalytics implements AppAnalytics {
  final List<AnalyticsEvent> logged = <AnalyticsEvent>[];

  @override
  Future<void> log(AnalyticsEvent event) async {
    logged.add(event);
  }

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
