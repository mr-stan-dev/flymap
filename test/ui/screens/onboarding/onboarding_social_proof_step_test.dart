import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/onboarding/steps/onboarding_social_proof_step.dart';
import 'package:flymap/ui/theme/app_theme.dart';

Widget _app() {
  return TranslationProvider(
    child: MaterialApp(
      locale: AppLocale.en.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: SafeArea(child: OnboardingSocialProofStep())),
    ),
  );
}

void main() {
  setUpAll(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows the flight count, laurels and verified testimonials', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Your flights will never feel the same.'), findsOneWidget);
    expect(find.text('10,000+'), findsOneWidget);
    expect(find.text('flights explored with Flymap'), findsOneWidget);
    expect(find.text('Trusted by curious flyers'), findsOneWidget);
    expect(
      find.text(
        'Very much liked it. I learned a lot of Geography during my flight to London',
      ),
      findsOneWidget,
    );
    expect(find.text('Natalija, Poland'), findsOneWidget);
    expect(find.text('N'), findsOneWidget);
    expect(find.text('I was searching for an app like this!'), findsOneWidget);
    expect(find.text('József, Hungary'), findsOneWidget);
    expect(find.text('J'), findsOneWidget);
    expect(
      find.text(
        'Watching my little plane move across the map felt kind of magical',
      ),
      findsOneWidget,
    );
    expect(find.text('Alexander, UK'), findsOneWidget);
    expect(
      find.text(
        'It feels like a mix of a geography explorer and an in-flight companion. The route timeline is cool.',
      ),
      findsOneWidget,
    );
    expect(find.text('Dina, Germany'), findsOneWidget);
    expect(find.text('D'), findsOneWidget);
    expect(
      find.text(
        'Use it all the time in flights across Europe. My kids love it too!',
      ),
      findsOneWidget,
    );
    expect(find.text('Adrian, UK'), findsOneWidget);
    expect(find.text('A'), findsNWidgets(2));
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(25));
    final avatarColors = tester
        .widgetList<CircleAvatar>(find.byType(CircleAvatar))
        .map((avatar) => avatar.backgroundColor)
        .toSet();
    expect(
      avatarColors,
      hasLength(OnboardingSocialProofStep.testimonialCardCount),
    );
    expect(
      find.text('Verified user testimonial will appear here.'),
      findsNothing,
    );
    expect(find.text('Name · Location'), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding-social-proof-laurel-left')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding-social-proof-laurel-right')),
      findsOneWidget,
    );
    const expectedAttributions = [
      'Natalija, Poland',
      'Adrian, UK',
      'Alexander, UK',
      'Dina, Germany',
      'József, Hungary',
    ];
    for (
      var index = 1;
      index <= OnboardingSocialProofStep.testimonialCardCount;
      index++
    ) {
      final card = find.byKey(ValueKey('onboarding-testimonial-card-$index'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.text(expectedAttributions[index - 1]),
        ),
        findsOneWidget,
      );
    }
  });
}
