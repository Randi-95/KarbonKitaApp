import '../../core/network/voucher_exception.dart';
import '../../models/leaderboard.dart';
import '../datasources/leaderboard_remote_datasource.dart';

/// Orkestrasi data papan peringkat.
class LeaderboardRepository {
  LeaderboardRepository(this._remote);

  final LeaderboardRemoteDatasource _remote;

  /// Ambil peringkat individu + posisi user dari backend.
  Future<LeaderboardBoard> getLeaderboard({
    required LeaderboardScope scope,
    required LeaderboardTimeframe timeframe,
  }) async {
    try {
      return await _remote.fetchLeaderboard(scope: scope, timeframe: timeframe);
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat leaderboard: $e');
    }
  }
}
