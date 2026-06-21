import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';

sealed class GeoQuizState extends Equatable {
  const GeoQuizState();

  @override
  List<Object?> get props => [];
}

final class GeoQuizLoading extends GeoQuizState {
  const GeoQuizLoading();
}

final class GeoQuizLoaded extends GeoQuizState {
  const GeoQuizLoaded({
    required this.summary,
    required this.regions,
    required this.progress,
    this.query = '',
    this.suggestions = const <GeoQuizAnswerSuggestion>[],
    this.feedback,
  });

  final GeoQuizSummary summary;
  final List<GeoQuizRegion> regions;
  final GeoQuizProgress progress;
  final String query;
  final List<GeoQuizAnswerSuggestion> suggestions;
  final GeoQuizAnswerFeedback? feedback;

  int get solvedCount => progress.solvedRegionIds.length;

  int get totalCount => regions.length;

  int get nextIndex =>
      totalCount == 0 ? 0 : (solvedCount + 1).clamp(1, totalCount).toInt();

  GeoQuizRegion? get currentRegion {
    for (final region in regions) {
      if (!progress.solvedRegionIds.contains(region.id)) return region;
    }
    return null;
  }

  String? get currentRegionId => currentRegion?.id;

  double get progressFraction {
    if (totalCount <= 0) return 0;
    return (solvedCount / totalCount).clamp(0.0, 1.0).toDouble();
  }

  bool get isComplete => totalCount > 0 && solvedCount >= totalCount;

  bool get hasMockRegions => regions.isNotEmpty;

  GeoQuizLoaded copyWith({
    List<GeoQuizRegion>? regions,
    GeoQuizProgress? progress,
    String? query,
    List<GeoQuizAnswerSuggestion>? suggestions,
    GeoQuizAnswerFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return GeoQuizLoaded(
      summary: summary,
      regions: regions ?? this.regions,
      progress: progress ?? this.progress,
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      feedback: clearFeedback ? null : feedback ?? this.feedback,
    );
  }

  @override
  List<Object?> get props => [
    summary,
    regions,
    progress,
    query,
    suggestions,
    feedback,
  ];
}

final class GeoQuizError extends GeoQuizState {
  const GeoQuizError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
