import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/wikipedia_articles/flight_search_wikipedia_articles_step.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/viewmodel/flight_preview_state.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  group('FlightSearchWikipediaArticlesStep', () {
    testWidgets('shows full article list for free users', (tester) async {
      final state = FlightPreviewState.initial().copyWith(
        step: CreateFlightStep.wikipediaArticles,
        articleCandidates: _candidates(4),
      );

      await tester.pumpWidget(
        _testApp(
          home: Scaffold(
            body: FlightSearchWikipediaArticlesStep(
              state: state,
              isProUser: false,
              onToggleArticle: (_) {},
              onToggleAll: () {},
              onStartDownload: () {},
            ),
          ),
        ),
      );

      expect(find.text('Article 1'), findsOneWidget);
      expect(find.text('Article 2'), findsOneWidget);
      expect(find.text('Article 3'), findsOneWidget);
      expect(find.text('Article 4'), findsOneWidget);
      expect(
        find.textContaining('Free plan includes up to 3 offline articles'),
        findsNothing,
      );
    });

    testWidgets('hides free-limit hint for Pro users', (tester) async {
      final state = FlightPreviewState.initial().copyWith(
        step: CreateFlightStep.wikipediaArticles,
        articleCandidates: _candidates(4),
      );

      await tester.pumpWidget(
        _testApp(
          home: Scaffold(
            body: FlightSearchWikipediaArticlesStep(
              state: state,
              isProUser: true,
              onToggleArticle: (_) {},
              onToggleAll: () {},
              onStartDownload: () {},
            ),
          ),
        ),
      );

      expect(find.text('Article 4'), findsOneWidget);
      expect(
        find.textContaining('Free plan includes up to 3 offline articles'),
        findsNothing,
      );
    });

    testWidgets('shows "Upgrade" for free users above 3 selections', (
      tester,
    ) async {
      final state = FlightPreviewState.initial().copyWith(
        step: CreateFlightStep.wikipediaArticles,
        articleCandidates: _candidates(4),
        selectedArticleUrls: const [
          'https://en.wikipedia.org/wiki/Article_1',
          'https://en.wikipedia.org/wiki/Article_2',
          'https://en.wikipedia.org/wiki/Article_3',
          'https://en.wikipedia.org/wiki/Article_4',
        ],
      );

      await tester.pumpWidget(
        _testApp(
          home: Scaffold(
            body: FlightSearchWikipediaArticlesStep(
              state: state,
              isProUser: false,
              onToggleArticle: (_) {},
              onToggleAll: () {},
              onStartDownload: () {},
            ),
          ),
        ),
      );

      expect(find.text('Upgrade'), findsOneWidget);
      expect(
        find.textContaining('Free plan includes up to 3 offline articles'),
        findsOneWidget,
      );
    });
  });
}

Widget _testApp({required Widget home}) {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: home,
    ),
  );
}

List<WikiArticleCandidate> _candidates(int count) {
  return List.generate(
    count,
    (index) => WikiArticleCandidate(
      url: 'https://en.wikipedia.org/wiki/Article_${index + 1}',
      title: 'Article ${index + 1}',
      languageCode: 'en',
    ),
  );
}
