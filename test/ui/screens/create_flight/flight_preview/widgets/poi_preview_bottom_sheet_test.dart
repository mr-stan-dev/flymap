import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/poi_wiki_preview.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/repository/poi_wiki_preview_repository.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/widgets/poi_preview_bottom_sheet.dart';
import 'package:flymap/usecase/get_poi_wiki_preview_use_case.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('opens as bottom sheet and not alert dialog', (tester) async {
    final useCase = _FakeGetPoiWikiPreviewUseCase();
    final preloaded = PoiWikiPreview(
      qid: 'Q1',
      title: 'Paris',
      summary:
          'Paris is the capital and most populous city of France with a long history and many landmarks.',
      sourceUrl: '',
      languageCode: 'en',
    );

    await tester.pumpWidget(_testApp(useCase: useCase, preloaded: preloaded));

    await tester.tap(find.text('Open POI'));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      find.textContaining('capital and most populous city'),
      findsOneWidget,
    );
  });

  testWidgets('disables Open action when source URL is empty', (tester) async {
    final useCase = _FakeGetPoiWikiPreviewUseCase();
    final preloaded = PoiWikiPreview(
      qid: 'Q2',
      title: 'No URL Place',
      summary: 'Some description.',
      sourceUrl: '',
      languageCode: 'en',
    );

    await tester.pumpWidget(_testApp(useCase: useCase, preloaded: preloaded));

    await tester.tap(find.text('Open POI'));
    await tester.pumpAndSettle();

    final openButton = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Open Wikipedia'),
    );
    expect(openButton.onPressed, isNull);
  });
}

Widget _testApp({
  required GetPoiWikiPreviewUseCase useCase,
  required PoiWikiPreview preloaded,
}) {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                await showPoiPreviewDialog(
                  context: context,
                  name: preloaded.title,
                  typeRaw: 'city',
                  qid: preloaded.qid,
                  wikiPreviewUseCase: useCase,
                  preloadedPreview: preloaded,
                );
              },
              child: const Text('Open POI'),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FakeGetPoiWikiPreviewUseCase extends GetPoiWikiPreviewUseCase {
  _FakeGetPoiWikiPreviewUseCase()
    : super(repository: _FakePoiWikiPreviewRepository());

  @override
  Future<PoiWikiPreview?> call({
    required String qid,
    required String preferredLanguageCode,
  }) async {
    return null;
  }
}

class _FakePoiWikiPreviewRepository implements PoiWikiPreviewRepository {
  @override
  Future<Map<String, PoiWikiPreview>> batchGetWikiPreviews({
    required List<String> qids,
    required String preferredLanguageCode,
  }) async {
    return {};
  }

  @override
  Future<PoiWikiPreview?> getWikiPreviewByQid({
    required String qid,
    required String preferredLanguageCode,
  }) async {
    return null;
  }
}
