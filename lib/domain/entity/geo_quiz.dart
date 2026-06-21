import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/learn_access.dart';

class GeoQuizSummary extends Equatable {
  const GeoQuizSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.totalCount,
    this.access = LearnAccess.free,
    this.iconName = 'public',
    this.geoJsonAssetPath,
  });

  final String id;
  final String title;
  final String subtitle;
  final int totalCount;
  final LearnAccess access;
  final String iconName;
  final String? geoJsonAssetPath;

  bool get isProOnly => access == LearnAccess.pro;

  @override
  List<Object?> get props => [
    id,
    title,
    subtitle,
    totalCount,
    access,
    iconName,
    geoJsonAssetPath,
  ];
}

class GeoQuizRegion extends Equatable {
  const GeoQuizRegion({
    required this.id,
    required this.names,
    this.aliases = const <String>[],
    this.countryCode,
  });

  final String id;
  final Map<String, String> names;
  final List<String> aliases;
  final String? countryCode;

  String labelForLanguage(String languageCode) {
    final localized = names[languageCode]?.trim();
    if (localized != null && localized.isNotEmpty) return localized;
    final english = names['en']?.trim();
    if (english != null && english.isNotEmpty) return english;
    return id;
  }

  Iterable<String> answerLabelsForLanguage(String languageCode) sync* {
    final localized = names[languageCode]?.trim();
    if (localized != null && localized.isNotEmpty) yield localized;
    final english = names['en']?.trim();
    if (english != null && english.isNotEmpty && english != localized) {
      yield english;
    }
    for (final alias in aliases) {
      final normalized = alias.trim();
      if (normalized.isNotEmpty) yield normalized;
    }
  }

  @override
  List<Object?> get props => [id, names, aliases, countryCode];
}

class GeoQuizProgress extends Equatable {
  const GeoQuizProgress({
    required this.quizId,
    this.solvedRegionIds = const {},
  });

  final String quizId;
  final Set<String> solvedRegionIds;

  int get solvedCount => solvedRegionIds.length;

  GeoQuizProgress copyWith({Set<String>? solvedRegionIds}) {
    return GeoQuizProgress(
      quizId: quizId,
      solvedRegionIds: solvedRegionIds ?? this.solvedRegionIds,
    );
  }

  @override
  List<Object?> get props => [quizId, solvedRegionIds];
}

class GeoQuizAnswerSuggestion extends Equatable {
  const GeoQuizAnswerSuggestion({
    required this.regionId,
    required this.label,
    this.countryCode,
  });

  final String regionId;
  final String label;
  final String? countryCode;

  @override
  List<Object?> get props => [regionId, label, countryCode];
}

class GeoQuizAnswerFeedback extends Equatable {
  const GeoQuizAnswerFeedback({required this.isCorrect, required this.label});

  final bool isCorrect;
  final String label;

  @override
  List<Object?> get props => [isCorrect, label];
}
