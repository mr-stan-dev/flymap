import 'package:equatable/equatable.dart';
import 'package:flymap/domain/entity/geo_quiz.dart';

sealed class GeoQuizListState extends Equatable {
  const GeoQuizListState();

  @override
  List<Object?> get props => [];
}

final class GeoQuizListLoading extends GeoQuizListState {
  const GeoQuizListLoading();
}

final class GeoQuizListLoaded extends GeoQuizListState {
  const GeoQuizListLoaded({
    required this.quizzes,
    required this.progressByQuizId,
  });

  final List<GeoQuizSummary> quizzes;
  final Map<String, GeoQuizProgress> progressByQuizId;

  GeoQuizProgress progressFor(String quizId) {
    return progressByQuizId[quizId] ?? GeoQuizProgress(quizId: quizId);
  }

  @override
  List<Object?> get props => [quizzes, progressByQuizId];
}

final class GeoQuizListError extends GeoQuizListState {
  const GeoQuizListError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
