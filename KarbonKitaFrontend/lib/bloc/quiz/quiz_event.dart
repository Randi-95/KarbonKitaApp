/// Event QuizBloc.
sealed class QuizEvent {
  const QuizEvent();
}

/// Muat kuis harian dari backend.
class DailyQuizLoaded extends QuizEvent {
  const DailyQuizLoaded({this.force = false});

  final bool force;
}

/// Kirim jawaban (label A/B/C/D) untuk kuis yang sedang tampil.
class QuizAnswered extends QuizEvent {
  const QuizAnswered(this.answer);

  final String answer;
}
