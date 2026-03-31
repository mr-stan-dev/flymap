import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/wiki_article_candidate.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/viewmodel/flight_search_screen_state.dart';
import 'package:flymap/ui/screens/create_flight/flight_search/widgets/steps/flight_search_wikipedia_articles_step.dart';

void main() {
  group('FlightSearchWikipediaArticlesStep', () {
    testWidgets('shows full article list for free users', (tester) async {
      final state = FlightSearchScreenState.initial().copyWith(
        step: CreateFlightStep.wikipediaArticles,
        articleCandidates: _candidates(4),
      );

      await tester.pumpWidget(
        MaterialApp(
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
      final state = FlightSearchScreenState.initial().copyWith(
        step: CreateFlightStep.wikipediaArticles,
        articleCandidates: _candidates(4),
      );

      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets(
      'shows "Upgrade & Download" for free users above 3 selections',
      (tester) async {
        final state = FlightSearchScreenState.initial().copyWith(
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
          MaterialApp(
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

        expect(find.text('Upgrade & Download'), findsOneWidget);
        expect(
          find.textContaining('Free plan includes up to 3 offline articles'),
          findsOneWidget,
        );
      },
    );
  });
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
