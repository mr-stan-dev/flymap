import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/design_system/design_system.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flymap/ui/widgets/app_advocacy_dialog.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  for (final testCase in <(String, AppAdvocacyAction)>[
    ('Share with friends', AppAdvocacyAction.share),
    ('Rate Flymap', AppAdvocacyAction.rate),
    ('Not now', AppAdvocacyAction.notNow),
  ]) {
    testWidgets('returns ${testCase.$2.name}', (tester) async {
      await tester.pumpWidget(_testApp());
      final context = tester.element(find.byType(Scaffold));
      final future = AppAdvocacyDialog.show(
        context,
        showRateAction: true,
        showShareAction: true,
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text(testCase.$1));
      await tester.pumpAndSettle();

      expect(await future, testCase.$2);
    });
  }

  testWidgets('can show only the remaining share action', (tester) async {
    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    AppAdvocacyDialog.show(
      context,
      showRateAction: false,
      showShareAction: true,
    );

    await tester.pumpAndSettle();

    expect(find.text('Share with friends'), findsOneWidget);
    expect(find.text('Rate Flymap'), findsNothing);
  });

  testWidgets('uses equal advocacy buttons and a lower-priority dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    AppAdvocacyDialog.show(
      context,
      showRateAction: true,
      showShareAction: true,
    );

    await tester.pumpAndSettle();

    expect(find.byType(SecondaryButton), findsNWidgets(2));
    expect(find.byType(TertiaryButton), findsOneWidget);
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
