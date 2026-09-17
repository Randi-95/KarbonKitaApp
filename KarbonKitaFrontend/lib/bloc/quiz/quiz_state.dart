import '../../models/daily_quiz.dart';

/// Status kuis harian.
enum QuizStatus { initial, loading, loaded, answering, error }

class QuizState {
  const QuizState({
    this.status = QuizStatus.initial,
    this.quiz,
    this.lastResult,
    this.errorMessage,
    this.isUnauthorized = false,
  });

  final QuizStatus status;
  final DailyQuiz? quiz;

  /// Hasil submit terakhir (null = belum jawab / sudah di-reset).
  final QuizAnswerResult? lastResult;
  final String? errorMessage;

  /// True bila backend 401 — UI harus logout, bukan sekadar retry.
  final bool isUnauthorized;

  QuizState copyWith({
    QuizStatus? status,
    DailyQuiz? quiz,
    QuizAnswerResult? lastResult,
    bool clearResult = false,
    String? errorMessage,
    bool? isUnauthorized,
  }) {
    return QuizState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      errorMessage: errorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
