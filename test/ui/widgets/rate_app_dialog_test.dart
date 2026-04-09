import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/theme/app_theme.dart';
import 'package:flymap/ui/widgets/rate_app_dialog.dart';

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('returns true when user taps Yes', (tester) async {
    bool? result;

    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    final future = RateAppDialog.show(context);

    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    result = await future;

    expect(result, isTrue);
  });

  testWidgets('returns false when user taps No', (tester) async {
    bool? result;

    await tester.pumpWidget(_testApp());
    final context = tester.element(find.byType(Scaffold));
    final future = RateAppDialog.show(context);

    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    result = await future;

    expect(result, isFalse);
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
