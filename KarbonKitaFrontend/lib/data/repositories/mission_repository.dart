import '../../core/network/mission_exception.dart';
import '../datasources/mission_remote_datasource.dart';
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