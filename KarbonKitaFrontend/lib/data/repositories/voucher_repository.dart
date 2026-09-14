import '../../core/network/voucher_exception.dart';
import '../datasources/voucher_remote_datasource.dart';
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
}
