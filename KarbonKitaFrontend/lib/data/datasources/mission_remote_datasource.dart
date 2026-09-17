import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/daily_quiz.dart';
import '../../models/mission.dart';

/// Akses mentah ke endpoint mission backend.
class MissionRemoteDatasource {
  MissionRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/missions/active
  /// Return list mission mobility & waste yang aktif.
  Future<List<Mission>> fetchActiveMissions() async {
    final envelope = await _client.get(ApiEndpoints.missionsActive);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Mission.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar misi tidak dikenali.');
  }

  /// GET /api/saga/quizzes
  /// Return kuis harian (Saga Map) - backend mengembalikan 1 quiz object.
  Future<DailyQuiz> fetchDailyQuiz() async {
    final envelope = await _client.get(ApiEndpoints.sagaQuizzes);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return DailyQuiz.fromJson(data);
    }
    throw const FormatException('Format kuis harian tidak dikenali.');
  }

  /// GET /api/saga/quizzes (delegasi)
  /// Representasi ringkas untuk daftar misi tab Misi.
  Future<List<Mission>> fetchSagaQuizzes() async {
    final quiz = await fetchDailyQuiz();
    return [quiz.toMission()];
  }

  /// POST /api/missions/verify-waste
  /// Upload foto untuk validasi AI sampah.
  /// TODO: Implement saat image upload diperlukan.
  Future<Map<String, dynamic>> verifyWaste({
    required int missionId,
    required String imagePath,
  }) async {
    throw UnimplementedError('Image upload belum diimplementasikan');
  }

  /// POST /api/missions/mobility-sync
  /// Sinkronisasi data mobilitas (GPS, jarak, durasi).
  Future<Map<String, dynamic>> mobilitySync({
    required int missionId,
    required String activityType, // 'cycling' | 'walking'
    required double distanceKm,
    required int durationSeconds,
    required List<Map<String, double>> gpsCoordinatesPath,
  }) async {
    final envelope = await _client.post(ApiEndpoints.mobilitySync, {
      'mission_id': missionId,
      'activity_type': activityType,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'gps_coordinates_path': gpsCoordinatesPath,
    });
    return envelope;
  }

  /// POST /api/saga/answer
  /// Submit jawaban kuis. Return envelope mentah (dipakai MissionBloc lama).
  Future<Map<String, dynamic>> submitQuizAnswer({
    required int quizId,
    required String answer,
  }) async {
    final envelope = await _client.post(ApiEndpoints.sagaAnswer, {
      'quiz_id': quizId,
      'answer': answer,
    });
    return envelope;
  }

  /// POST /api/saga/answer (typed)
  /// Return hasil benar/salah + reward. 409/401 diteruskan sebagai exception.
  Future<QuizAnswerResult> answerQuiz({
    required int quizId,
    required String answer,
  }) async {
    final envelope = await _client.post(ApiEndpoints.sagaAnswer, {
      'quiz_id': quizId,
      'answer': answer.toUpperCase(),
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return QuizAnswerResult.fromJson(data);
    }
    throw const FormatException('Format hasil kuis tidak dikenali.');
  }
}
