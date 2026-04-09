import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/entity/feedback_category.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen.dart';
import 'package:flymap/ui/screens/feedback/feedback_screen_args.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flymap/usecase/submit_feedback_use_case.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('sends entered feedback text', (tester) async {
    final useCase = _FakeSubmitFeedbackUseCase();

    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    final route = Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FeedbackScreen(
          args: const FeedbackScreenArgs(source: 'test_source', isPro: false),
          submitFeedbackUseCase: useCase,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Bug report'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Great app for flights',
    );
    await tester.enterText(find.byType(TextField).last, 'pilot@example.com');
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    final submitted = await route;

    expect(submitted, isTrue);
    expect(useCase.requests.single.message, 'Great app for flights');
    expect(useCase.requests.single.category, FeedbackCategory.bugReport);
    expect(useCase.requests.single.source, 'test_source');
    expect(useCase.requests.single.isPro, isFalse);
    expect(useCase.requests.single.email, 'pilot@example.com');
  });

  testWidgets('preselects General by default', (tester) async {
    final useCase = _FakeSubmitFeedbackUseCase();

    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    final route = Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FeedbackScreen(
          args: const FeedbackScreenArgs(source: 'test_source', isPro: false),
          submitFeedbackUseCase: useCase,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Default category check',
    );
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    final submitted = await route;

    expect(submitted, isTrue);
    expect(useCase.requests.single.category, FeedbackCategory.general);
  });

  testWidgets('shows validation error for invalid email', (tester) async {
    final useCase = _FakeSubmitFeedbackUseCase();

    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    unawaited(
      Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => FeedbackScreen(
            args: const FeedbackScreenArgs(source: 'test_source', isPro: false),
            submitFeedbackUseCase: useCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Some feedback');
    await tester.enterText(find.byType(TextField).last, 'not-an-email');
    await tester.pumpAndSettle();

    expect(
      find.text('Please enter a valid email or leave it empty.'),
      findsOneWidget,
    );
    expect(useCase.requests, isEmpty);
  });
}

Widget _testApp() {
  return TranslationProvider(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );
}

class _FakeSubmitFeedbackUseCase implements SubmitFeedbackUseCase {
  final List<SubmitFeedbackRequest> requests = <SubmitFeedbackRequest>[];

  @override
  Future<bool> call(SubmitFeedbackRequest request) async {
    requests.add(request);
    return true;
  }
}
