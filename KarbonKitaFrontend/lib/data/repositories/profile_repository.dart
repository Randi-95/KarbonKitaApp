import '../../core/network/voucher_exception.dart';
import '../../models/activity.dart';
import '../../models/level_tier.dart';
import '../datasources/profile_remote_datasource.dart';

/// Orkestrasi data profil / level tiers / aktivitas.
class ProfileRepository {
  ProfileRepository(this._remote);

  final ProfileRemoteDatasource _remote;

  /// Ambil 3 tier lencana level + status unlock dari backend.
  Future<LevelTiersData> getLevels() async {
    try {
      return await _remote.fetchLevels();
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat level: $e');
    }
  }

  /// Ambil aktivitas terbaru user dari backend.
  Future<List<UserActivity>> getActivities({int limit = 5}) async {
    try {
      return await _remote.fetchActivities(limit: limit);
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat aktivitas: $e');
    }
  }
}
