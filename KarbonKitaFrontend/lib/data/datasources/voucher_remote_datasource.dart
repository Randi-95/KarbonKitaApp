import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/voucher.dart';

/// Akses mentah ke endpoint voucher & dashboard backend.
class VoucherRemoteDatasource {
  VoucherRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/vouchers
  /// Return list voucher aktif, stok tersedia, belum kedaluwarsa.
  Future<List<Voucher>> fetchVouchers() async {
    final envelope = await _client.get(ApiEndpoints.vouchers);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Voucher.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar voucher tidak dikenali.');
  }

  /// GET /api/user/dashboard
  /// Ambil saldo eco_points user dari `data.user.eco_points`.
  Future<int> fetchEcoPoints() async {
    final envelope = await _client.get(ApiEndpoints.userDashboard);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      final user = data['user'];
      if (user is Map<String, dynamic>) {
        return (user['eco_points'] as num? ?? 0).toInt();
      }
    }
    throw const FormatException('Format saldo poin tidak dikenali.');
  }
}
