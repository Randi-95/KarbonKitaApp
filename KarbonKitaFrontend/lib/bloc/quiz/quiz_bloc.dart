import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/mission_exception.dart';
import '../../data/repositories/mission_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

/// BLoC kuis harian: `GET /saga/quizzes` + `POST /saga/answer`.
/// Backend hanya beri 1 soal/hari, boleh retry sampai benar (XP saja).
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc(this._repository) : super(const QuizState()) {
    on<DailyQuizLoaded>(_onLoaded);
    on<QuizAnswered>(_onAnswered);
  }

  final MissionRepository _repository;

  Future<void> _onLoaded(DailyQuizLoaded event, Emitter<QuizState> emit) async {
    if (!event.force &&
        state.status == QuizStatus.loaded &&
        state.quiz != null) {
      return;
    }
    final hasCache = state.quiz != null;
    emit(
      state.copyWith(
        status: hasCache ? state.status : QuizStatus.loading,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final quiz = await _repository.getDailyQuiz();
      emit(state.copyWith(status: QuizStatus.loaded, quiz: quiz));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: hasCache ? QuizStatus.loaded : QuizStatus.error,
          errorMessage: e.message,
        ),
      );
    } on MissionException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: hasCache ? QuizStatus.loaded : QuizStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: hasCache ? QuizStatus.loaded : QuizStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onAnswered(QuizAnswered event, Emitter<QuizState> emit) async {
    final quiz = state.quiz;
    if (quiz == null || state.status == QuizStatus.answering) return;

    emit(
      state.copyWith(
        status: QuizStatus.answering,
        clearResult: true,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.answerQuiz(
        quizId: quiz.id,
        answer: event.answer,
      );
      if (result.isCorrect) {
        // Ambil ulang agar correct_answer + explanation tersedia.
        try {
          final fresh = await _repository.getDailyQuiz();
          emit(
            state.copyWith(
              status: QuizStatus.loaded,
              quiz: fresh,
              lastResult: result,
            ),
          );
        } catch (_) {
          emit(state.copyWith(status: QuizStatus.loaded, lastResult: result));
        }
      } else {
        // Salah boleh coba lagi — quiz tetap, pilihan di-reset UI.
        emit(state.copyWith(status: QuizStatus.loaded, lastResult: result));
      }
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(status: QuizStatus.loaded, isUnauthorized: true));
        return;
      }
      emit(state.copyWith(status: QuizStatus.loaded, errorMessage: e.message));
    } on MissionException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(status: QuizStatus.loaded, isUnauthorized: true));
        return;
      }
      if (e.statusCode == 409) {
        // Sudah benar hari ini (race) — sinkronkan status selesai.
        add(const DailyQuizLoaded(force: true));
        return;
      }
      emit(state.copyWith(status: QuizStatus.loaded, errorMessage: e.message));
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizStatus.loaded,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }
}
