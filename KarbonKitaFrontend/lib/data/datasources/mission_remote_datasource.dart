import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
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
  /// Return kuis harian (Saga Map) - backend mengembalikan 1 quiz object, bukan list.
  Future<List<Mission>> fetchSagaQuizzes() async {
    final envelope = await _client.get(ApiEndpoints.sagaQuizzes);
    final data = envelope['data'];
    // Backend return single quiz object (Map), bukan List
    if (data is Map<String, dynamic>) {
      return [_quizToMission(data)];
    } else if (data is List) {
      // Fallback jika backend berubah jadi list
      return data
          .whereType<Map<String, dynamic>>()
          .map(_quizToMission)
          .toList();
    }
    throw const FormatException('Format daftar kuis tidak dikenali.');
  }

  /// Convert quiz JSON from backend to Mission model
  Mission _quizToMission(Map<String, dynamic> json) {
    // Backend QuizResource fields: id, mission_id, mission_title, question, options, order, is_completed_today, xp_reward
    // Map to Mission fields
    return Mission(
      id: (json['id'] as num?)?.toInt() ?? (json['mission_id'] as num?)?.toInt() ?? 0,
      title: json['mission_title'] as String? ?? json['question'] as String? ?? 'Kuis Harian',
      description: json['question'] as String? ?? 'Jawab kuis untuk mendapatkan XP',
      category: 'quiz',
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      pointsReward: 0, // Quiz tidak beri eco_points
      icon: '',
    );
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
  /// Submit jawaban kuis.
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
}