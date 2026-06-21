import 'package:flymap/i18n/strings.g.dart';

class CountryNameUtils {
  CountryNameUtils._();

  static const List<String> _countryCodes = <String>[
    'AE',
    'AF',
    'AG',
    'AL',
    'AM',
    'AO',
    'AR',
    'AT',
    'AU',
    'AZ',
    'BA',
    'BB',
    'BD',
    'BE',
    'BF',
    'BG',
    'BH',
    'BI',
    'BJ',
    'BN',
    'BO',
    'BR',
    'BS',
    'BT',
    'BW',
    'BY',
    'BZ',
    'CA',
    'CD',
    'CF',
    'CG',
    'CH',
    'CI',
    'CL',
    'CM',
    'CN',
    'CO',
    'CR',
    'CU',
    'CV',
    'CY',
    'CZ',
    'DE',
    'DJ',
    'DK',
    'DO',
    'DZ',
    'EC',
    'EE',
    'EG',
    'EH',
    'ER',
    'ES',
    'ET',
    'FI',
    'FJ',
    'FR',
    'GA',
    'GB',
    'GE',
    'GF',
    'GH',
    'GM',
    'GN',
    'GP',
    'GQ',
    'GR',
    'GT',
    'GW',
    'GY',
    'HK',
    'HN',
    'HR',
    'HT',
    'HU',
    'ID',
    'IE',
    'IL',
    'IN',
    'IQ',
    'IR',
    'IS',
    'IT',
    'JM',
    'JO',
    'JP',
    'KE',
    'KG',
    'KH',
    'KM',
    'KP',
    'KR',
    'KW',
    'KZ',
    'LA',
    'LB',
    'LK',
    'LR',
    'LS',
    'LT',
    'LU',
    'LV',
    'LY',
    'MA',
    'MD',
    'ME',
    'MG',
    'MK',
    'ML',
    'MM',
    'MN',
    'MO',
    'MQ',
    'MR',
    'MU',
    'MV',
    'MW',
    'MT',
    'MX',
    'MY',
    'MZ',
    'NA',
    'NC',
    'NE',
    'NG',
    'NI',
    'NL',
    'NO',
    'NP',
    'NZ',
    'OM',
    'PA',
    'PE',
    'PG',
    'PH',
    'PK',
    'PL',
    'PR',
    'PS',
    'PT',
    'PY',
    'QA',
    'RE',
    'RO',
    'RS',
    'RU',
    'RW',
    'SA',
    'SB',
    'SD',
    'SE',
    'SG',
    'SI',
    'SK',
    'SL',
    'SN',
    'SO',
    'SR',
    'SS',
    'ST',
    'SV',
    'SY',
    'SZ',
    'TD',
    'TG',
    'TH',
    'TJ',
    'TL',
    'TM',
    'TN',
    'TR',
    'TT',
    'TW',
    'TZ',
    'UA',
    'UG',
    'US',
    'UY',
    'UZ',
    'VE',
    'VI',
    'VN',
    'YE',
    'ZA',
    'ZM',
    'ZW',
  ];

  static final Translations _englishTranslations = AppLocale.en.buildSync();
  static final Map<String, String> _englishNameToCode = {
    for (final code in _countryCodes)
      _normalizeCountryName(_englishNameForCode(code)): code,
  };
  static final Map<String, Map<String, String>> _localizedNameToCodeCache = {};

  static List<String> get countryCodes => _countryCodes;

  static String? toCode(String name, {String? languageCode}) {
    final normalized = _normalizeCountryName(name);
    if (normalized.isEmpty) return null;

    final requestedLanguageCode =
        (languageCode ?? LocaleSettings.currentLocale.languageCode)
            .trim()
            .toLowerCase();
    final candidateMaps = <Map<String, String>>[
      if (requestedLanguageCode != 'en')
        _localizedNameToCode(requestedLanguageCode),
      _englishNameToCode,
    ];

    for (final nameToCode in candidateMaps) {
      if (nameToCode.containsKey(normalized)) {
        return nameToCode[normalized];
      }
    }

    for (final nameToCode in candidateMaps) {
      for (final entry in nameToCode.entries) {
        if (entry.key.contains(normalized) || normalized.contains(entry.key)) {
          if (normalized.length > 3 || entry.key.length > 3) {
            return entry.value;
          }
        }
      }
    }

    return null;
  }

  static String fromCode(String code, {String? languageCode}) {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return code;

    final requestedLanguageCode =
        (languageCode ?? LocaleSettings.currentLocale.languageCode)
            .trim()
            .toLowerCase();
    final path = 'countries.$normalized';

    final translations = requestedLanguageCode == 'en'
        ? _englishTranslations
        : LocaleSettings.instance.currentTranslations;
    final translated = translations[path];
    if (translated is String && translated.isNotEmpty) {
      return translated;
    }

    return _englishNameForCode(normalized);
  }

  static String _englishNameForCode(String code) {
    final translated = _englishTranslations['countries.$code'];
    if (translated is String && translated.isNotEmpty) {
      return translated;
    }
    return code;
  }

  static Map<String, String> _localizedNameToCode(String languageCode) {
    if (languageCode == 'en') return _englishNameToCode;
    final cached = _localizedNameToCodeCache[languageCode];
    if (cached != null) return cached;

    final currentLanguageCode = LocaleSettings.currentLocale.languageCode
        .trim()
        .toLowerCase();
    if (currentLanguageCode != languageCode) {
      return const <String, String>{};
    }

    final translations = LocaleSettings.instance.currentTranslations;
    final localized = <String, String>{};
    for (final code in _countryCodes) {
      final translated = translations['countries.$code'];
      if (translated is! String) continue;
      final normalized = _normalizeCountryName(translated);
      if (normalized.isEmpty) continue;
      localized[normalized] = code;
    }
    _localizedNameToCodeCache[languageCode] = localized;
    return localized;
  }

  static String _normalizeCountryName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('å', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ñ', 'n')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ÿ', 'y');
  }
}
