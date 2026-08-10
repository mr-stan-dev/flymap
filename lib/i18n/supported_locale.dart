import 'package:flymap/i18n/strings.g.dart';

enum SupportedLocale {
  english(languageCode: 'en', appLocale: AppLocale.en, flagCountryCode: 'GB'),
  spanish(languageCode: 'es', appLocale: AppLocale.es, flagCountryCode: 'ES'),
  french(languageCode: 'fr', appLocale: AppLocale.fr, flagCountryCode: 'FR'),
  german(languageCode: 'de', appLocale: AppLocale.de, flagCountryCode: 'DE');

  const SupportedLocale({
    required this.languageCode,
    required this.appLocale,
    required this.flagCountryCode,
  });

  final String languageCode;
  final AppLocale appLocale;
  final String flagCountryCode;

  static SupportedLocale englishFallback(String? languageCode) {
    return fromLanguageCode(languageCode) ?? SupportedLocale.english;
  }

  static SupportedLocale? fromLanguageCode(String? languageCode) {
    final normalized = languageCode?.trim().toLowerCase().replaceAll('_', '-');
    if (normalized == null || normalized.isEmpty) return null;
    if (!RegExp(r'^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$').hasMatch(normalized)) {
      return null;
    }
    final baseLanguageCode = normalized.split('-').first;
    for (final locale in SupportedLocale.values) {
      if (locale.languageCode == baseLanguageCode) return locale;
    }
    return null;
  }
}
