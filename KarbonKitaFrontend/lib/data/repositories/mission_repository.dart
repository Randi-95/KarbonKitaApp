import '../../core/network/auth_exception.dart';
import '../../core/network/mission_exception.dart';
import '../datasources/mission_remote_datasource.dart';
import '../../models/daily_quiz.dart';
import '../../models/mission.dart';

/// Orkestrasi data mission.
class MissionRepository {
  MissionRepository(this._remote);

  final MissionRemoteDatasource _remote;

  /// Ambil misi aktif (mobility + waste) dari backend.
  Future<List<Mission>> getActiveMissions() async {
    try {
      return await _remote.fetchActiveMissions();
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal memuat misi aktif: $e');
    }
  }

  /// Ambil kuis harian (Saga Map) dari backend.
  Future<List<Mission>> getSagaQuizzes() async {
    try {
      return await _remote.fetchSagaQuizzes();
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal memuat kuis harian: $e');
    }
  }

  /// Ambil kuis harian (typed) dari backend.
  Future<DailyQuiz> getDailyQuiz() async {
    try {
      return await _remote.fetchDailyQuiz();
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      // Dio melempar AuthException langsung — pertahankan statusCode (401).
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw MissionException('Gagal memuat kuis harian: $e');
    }
  }

  /// Submit jawaban kuis (typed). 409/401 diteruskan dengan statusCode.
  Future<QuizAnswerResult> answerQuiz({
    required int quizId,
    required String answer,
  }) async {
    try {
      return await _remote.answerQuiz(quizId: quizId, answer: answer);
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw MissionException('Gagal submit jawaban kuis: $e');
    }
  }

  /// Sinkronisasi aktivitas mobilitas.
  Future<Map<String, dynamic>> syncMobility({
    required int missionId,
    required String activityType,
    required double distanceKm,
    required int durationSeconds,
    required List<Map<String, double>> gpsCoordinatesPath,
  }) async {
    try {
      return await _remote.mobilitySync(
        missionId: missionId,
        activityType: activityType,
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
        gpsCoordinatesPath: gpsCoordinatesPath,
      );
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal sinkronisasi mobilitas: $e');
    }
  }

  /// Submit jawaban kuis.
  Future<Map<String, dynamic>> submitQuizAnswer({
    required int quizId,
    required String answer,
  }) async {
    try {
      return await _remote.submitQuizAnswer(quizId: quizId, answer: answer);
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal submit jawaban kuis: $e');
    }
  }
}
