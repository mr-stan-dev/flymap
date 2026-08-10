import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/i18n/supported_locale.dart';

void main() {
  group('SupportedLocale.fromLanguageCode', () {
    test('resolves supported base locales', () {
      expect(SupportedLocale.fromLanguageCode('en'), SupportedLocale.english);
      expect(SupportedLocale.fromLanguageCode('es'), SupportedLocale.spanish);
      expect(SupportedLocale.fromLanguageCode('fr'), SupportedLocale.french);
      expect(SupportedLocale.fromLanguageCode('de'), SupportedLocale.german);
    });

    test('resolves regional and underscore locale tags to the base locale', () {
      expect(
        SupportedLocale.fromLanguageCode('es-MX'),
        SupportedLocale.spanish,
      );
      expect(
        SupportedLocale.fromLanguageCode('ES_mx'),
        SupportedLocale.spanish,
      );
      expect(SupportedLocale.fromLanguageCode('fr-CA'), SupportedLocale.french);
      expect(SupportedLocale.fromLanguageCode('de_CH'), SupportedLocale.german);
      expect(
        SupportedLocale.fromLanguageCode('en-GB'),
        SupportedLocale.english,
      );
    });

    test('does not match unsupported languages', () {
      expect(SupportedLocale.fromLanguageCode('pt-BR'), isNull);
      expect(SupportedLocale.fromLanguageCode('es--MX'), isNull);
      expect(SupportedLocale.fromLanguageCode('not-a-locale'), isNull);
      expect(SupportedLocale.fromLanguageCode(''), isNull);
      expect(SupportedLocale.fromLanguageCode(null), isNull);
    });
  });
}
