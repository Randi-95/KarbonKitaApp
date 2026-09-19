import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/mission_exception.dart';
import '../../data/repositories/mission_repository.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

/// BLoC Saga: strip kuis harian + daftar node + sesi multi-soal per node.
/// Aturan sesi backend: benar = +XP, salah = hangus (409 bila diulang).
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  QuizBloc(this._repository) : super(const QuizState()) {
    on<DailyQuizLoaded>(_onLoaded);
    on<SagaNodesLoaded>(_onNodesLoaded);
    on<NodeSessionLoaded>(_onSessionLoaded);
    on<SessionQuestionNext>(_onQuestionNext);
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

  Future<void> _onNodesLoaded(
    SagaNodesLoaded event,
    Emitter<QuizState> emit,
  ) async {
    if (!event.force &&
        state.nodesStatus == SagaNodesStatus.loaded &&
        state.nodes.isNotEmpty) {
      return;
    }
    final hasCache = state.nodes.isNotEmpty;
    emit(
      state.copyWith(
        nodesStatus: hasCache ? state.nodesStatus : SagaNodesStatus.loading,
        nodesErrorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final nodes = await _repository.getSagaNodes();
      emit(state.copyWith(nodesStatus: SagaNodesStatus.loaded, nodes: nodes));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          nodesStatus: hasCache
              ? SagaNodesStatus.loaded
              : SagaNodesStatus.error,
          nodesErrorMessage: e.message,
        ),
      );
    } on MissionException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          nodesStatus: hasCache
              ? SagaNodesStatus.loaded
              : SagaNodesStatus.error,
          nodesErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          nodesStatus: hasCache
              ? SagaNodesStatus.loaded
              : SagaNodesStatus.error,
          nodesErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onSessionLoaded(
    NodeSessionLoaded event,
    Emitter<QuizState> emit,
  ) async {
    if (!event.force &&
        state.sessionStatus == SessionStatus.loaded &&
        state.session?.missionId == event.missionId) {
      return;
    }
    final hasCache = state.session?.missionId == event.missionId;
    emit(
      state.copyWith(
        sessionStatus: hasCache ? state.sessionStatus : SessionStatus.loading,
        sessionErrorMessage: null,
        clearResult: true,
        isUnauthorized: false,
      ),
    );
    try {
      final session = await _repository.getNodeQuestions(event.missionId);
      final first = session.firstUnansweredIndex;
      emit(
        state.copyWith(
          sessionStatus: SessionStatus.loaded,
          session: session,
          sessionIndex: first == -1 ? 0 : first,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          sessionStatus: hasCache ? SessionStatus.loaded : SessionStatus.error,
          sessionErrorMessage: e.message,
        ),
      );
    } on MissionException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          sessionStatus: hasCache ? SessionStatus.loaded : SessionStatus.error,
          sessionErrorMessage: e.statusCode == 403
              ? 'Babak ini terkunci hari ini.'
              : e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sessionStatus: hasCache ? SessionStatus.loaded : SessionStatus.error,
          sessionErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  /// Lanjut ke soal sesi berikutnya yang belum dijawab (feedback ditutup).
  /// Bila tidak ada lagi, UI menampilkan ringkasan (sesi selesai).
  void _onQuestionNext(SessionQuestionNext event, Emitter<QuizState> emit) {
    final session = state.session;
    if (session == null) return;
    var idx = state.sessionIndex + 1;
    while (idx < session.questions.length &&
        session.questions[idx].isCompletedToday) {
      idx++;
    }
    emit(state.copyWith(sessionIndex: idx, clearResult: true));
  }

  /// Jawab soal sesi yang sedang tampil. Salah = hangus (tidak ada retry),
  /// kunci jawaban di-refresh dari backend agar feedback jujur.
  Future<void> _onAnswered(QuizAnswered event, Emitter<QuizState> emit) async {
    final session = state.session;
    if (session == null ||
        state.sessionIndex >= session.questions.length ||
        state.status == QuizStatus.answering) {
      return;
    }
    final question = session.questions[state.sessionIndex];
    // Soal hangus/sudah dijawab tidak bisa dikirim ulang.
    if (question.isCompletedToday || state.lastResult != null) return;

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
        quizId: question.id,
        answer: event.answer,
      );
      // Ambil ulang sesi agar jawaban terungkap + progres akurat.
      try {
        final fresh = await _repository.getNodeQuestions(session.missionId);
        emit(
          state.copyWith(
            status: QuizStatus.loaded,
            session: fresh,
            lastResult: result,
          ),
        );
      } catch (_) {
        emit(state.copyWith(status: QuizStatus.loaded, lastResult: result));
      }
      if (result.nodeCompleted) {
        // Segarkan peta + strip harian.
        add(const SagaNodesLoaded(force: true));
        add(const DailyQuizLoaded(force: true));
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
        // Soal sudah terjawab (hangus/race) — sinkronkan sesi.
        add(NodeSessionLoaded(session.missionId, force: true));
        emit(
          state.copyWith(
            status: QuizStatus.loaded,
            errorMessage: 'Soal ini sudah terjawab (hangus).',
          ),
        );
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
