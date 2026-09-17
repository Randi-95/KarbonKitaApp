import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_bloc.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_event.dart';
import 'package:karbon_kita_app/bloc/quiz/quiz_state.dart';
import 'package:karbon_kita_app/core/network/auth_exception.dart';
import 'package:karbon_kita_app/core/network/dio_client.dart';
import 'package:karbon_kita_app/core/network/mission_exception.dart';
import 'package:karbon_kita_app/data/datasources/mission_remote_datasource.dart';
import 'package:karbon_kita_app/data/repositories/mission_repository.dart';
import 'package:karbon_kita_app/models/daily_quiz.dart';

Map<String, dynamic> _quizJson({bool completed = false}) => {
  'id': 4,
  'mission_id': 9,
  'mission_title': 'Kuis Pilah Sampah',
  'question': 'Warna tempat sampah untuk anorganik daur ulang?',
  'options': {'A': 'Hijau', 'B': 'Kuning', 'C': 'Merah', 'D': 'Biru'},
  'order': 0,
  'is_completed_today': completed,
  'xp_reward': 50,
  if (completed) 'correct_answer': 'B',
  if (completed) 'explanation': 'Kuning untuk anorganik daur ulang.',
};

/// Datasource yang selalu gagal seperti Dio saat HTTP error.
class _ThrowingDatasource extends MissionRemoteDatasource {
  _ThrowingDatasource() : super(DioClient());

  @override
  Future<DailyQuiz> fetchDailyQuiz() {
    throw const AuthException('Salah.', statusCode: 422);
  }
}

class FakeMissionRepository extends MissionRepository {
  FakeMissionRepository({this.quiz, this.answer, this.error})
    : super(MissionRemoteDatasource(DioClient()));

  DailyQuiz? quiz;
  QuizAnswerResult? answer;
  Exception? error;

  @override
  Future<DailyQuiz> getDailyQuiz() async {
    if (error != null) throw error!;
    return quiz!;
  }

  @override
  Future<QuizAnswerResult> answerQuiz({
    required int quizId,
    required String answer,
  }) async {
    if (error != null) throw error!;
    return this.answer!;
  }
}

void main() {
  group('DailyQuiz parsing (kontrak QuizResource)', () {
    test('fromJson baca soal + opsi map + belum selesai', () {
      final quiz = DailyQuiz.fromJson(_quizJson());

      expect(quiz.id, 4);
      expect(quiz.missionTitle, 'Kuis Pilah Sampah');
      expect(quiz.options, hasLength(4));
      expect(quiz.options[1].label, 'B');
      expect(quiz.options[1].text, 'Kuning');
      expect(quiz.isCompletedToday, isFalse);
      expect(quiz.correctAnswer, isNull);
      expect(quiz.explanation, isNull);
      expect(quiz.xpReward, 50);
    });

    test('selesai -> correct_answer + explanation tersedia', () {
      final quiz = DailyQuiz.fromJson(_quizJson(completed: true));

      expect(quiz.isCompletedToday, isTrue);
      expect(quiz.correctAnswer, 'B');
      expect(quiz.explanation, contains('Kuning'));
    });

    test('toMission untuk daftar misi tab Misi', () {
      final mission = DailyQuiz.fromJson(_quizJson()).toMission();
      expect(mission.category, 'quiz');
      expect(mission.xpReward, 50);
      expect(mission.pointsReward, 0);
    });
  });

  group('QuizAnswerResult parsing', () {
    test('fromJson baca benar + reward', () {
      final result = QuizAnswerResult.fromJson({
        'is_correct': true,
        'xp_earned': 50,
        'new_xp': 2400,
        'new_level': 'Earth Warrior 7',
        'streak_days': 8,
        'user_mission_id': 11,
      });
      expect(result.isCorrect, isTrue);
      expect(result.xpEarned, 50);
      expect(result.newLevel, 'Earth Warrior 7');
      expect(result.attemptsToday, 0);
    });
  });

  group('QuizBloc', () {
    test('loaded -> status loaded + soal', () async {
      final bloc = FakeMissionRepository(quiz: DailyQuiz.fromJson(_quizJson()));
      final quizBloc = QuizBloc(bloc);
      final future = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.status == QuizStatus.loaded &&
                s.quiz?.question.contains('anorganik') == true,
          ),
        ),
      );
      quizBloc.add(const DailyQuizLoaded());
      await future;
      await quizBloc.close();
    });

    test('jawab benar -> result + quiz di-refresh', () async {
      final repo = FakeMissionRepository(
        quiz: DailyQuiz.fromJson(_quizJson()),
        answer: QuizAnswerResult.fromJson({
          'is_correct': true,
          'xp_earned': 50,
          'new_xp': 2400,
          'new_level': 'Earth Warrior 7',
          'streak_days': 8,
          'user_mission_id': 11,
        }),
      );
      final quizBloc = QuizBloc(repo);
      // Siapkan quiz dulu, lalu jawab.
      final loaded = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>((s) => s.status == QuizStatus.loaded),
        ),
      );
      quizBloc.add(const DailyQuizLoaded());
      await loaded;

      // Setelah benar, bloc refetch -> quiz selesai + result benar.
      repo.quiz = DailyQuiz.fromJson(_quizJson(completed: true));
      final answered = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.status == QuizStatus.loaded &&
                s.lastResult?.isCorrect == true &&
                s.quiz?.isCompletedToday == true,
          ),
        ),
      );
      quizBloc.add(const QuizAnswered('B'));
      await answered;
      await quizBloc.close();
    });

    test('jawab salah -> result salah, quiz tetap (boleh retry)', () async {
      final quizBloc = QuizBloc(
        FakeMissionRepository(
          quiz: DailyQuiz.fromJson(_quizJson()),
          answer: QuizAnswerResult.fromJson({
            'is_correct': false,
            'attempts_today': 2,
            'user_mission_id': 12,
          }),
        ),
      );
      final loaded = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>((s) => s.status == QuizStatus.loaded),
        ),
      );
      quizBloc.add(const DailyQuizLoaded());
      await loaded;

      final answered = expectLater(
        quizBloc.stream,
        emitsThrough(
          predicate<QuizState>(
            (s) =>
                s.status == QuizStatus.loaded &&
                s.lastResult?.isCorrect == false &&
                s.quiz?.isCompletedToday == false,
          ),
        ),
      );
      quizBloc.add(const QuizAnswered('A'));
      await answered;
      await quizBloc.close();
    });

    test('401 -> isUnauthorized (UI wajib logout)', () async {
      final quizBloc = QuizBloc(
        FakeMissionRepository(
          error: const AuthException('Unauthenticated.', statusCode: 401),
        ),
      );
      final future = expectLater(
        quizBloc.stream,
        emitsThrough(predicate<QuizState>((s) => s.isUnauthorized)),
      );
      quizBloc.add(const DailyQuizLoaded());
      await future;
      await quizBloc.close();
    });

    test('repository pertahankan statusCode AuthException', () async {
      final repo = MissionRepository(_ThrowingDatasource());
      try {
        await repo.getDailyQuiz();
        fail('harus lempar');
      } on MissionException catch (e) {
        expect(e.statusCode, 422);
        expect(e.message, 'Salah.');
      }
    });
  });
}
