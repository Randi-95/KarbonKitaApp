import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../datasources/voucher_remote_datasource.dart';
import '../../models/dashboard.dart';
import '../../models/my_voucher.dart';
import '../../models/voucher.dart';

/// Orkestrasi data marketplace voucher.
class VoucherRepository {
  VoucherRepository(this._remote);

  final VoucherRemoteDatasource _remote;

  /// Ambil daftar voucher yang bisa diklaim dari backend.
  Future<List<Voucher>> getVouchers() async {
    try {
      return await _remote.fetchVouchers();
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat voucher: $e');
    }
  }

  /// Ambil paket dashboard Beranda dari backend.
  Future<DashboardData> getDashboard() async {
    try {
      return await _remote.fetchDashboard();
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat dashboard: $e');
    }
  }

  /// Ambil saldo eco_points user dari backend.
  Future<int> getEcoPoints() async {
    try {
      return await _remote.fetchEcoPoints();
    } on VoucherException {
      rethrow;
    } catch (e) {
      throw VoucherException('Gagal memuat saldo poin: $e');
    }
  }

  /// Ambil inventaris dompet voucher dari backend.
  Future<MyVoucherInventory> getMyVouchers() async {
    try {
      return await _remote.fetchMyVouchers();
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      // Dio melempar AuthException langsung — pertahankan statusCode (401).
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal memuat dompet voucher: $e');
    }
  }

  /// Klaim voucher dengan poin. 401/422/500 diteruskan dengan statusCode.
  Future<ClaimResult> claimVoucher({required int voucherId}) async {
    try {
      return await _remote.claimVoucher(voucherId: voucherId);
    } on VoucherException {
      rethrow;
    } on AuthException catch (e) {
      throw VoucherException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
      );
    } catch (e) {
      throw VoucherException('Gagal klaim voucher: $e');
    }
  }
}
