import '../../core/storage/token_storage.dart';
import '../../models/auth_response.dart';
import '../../models/user.dart';
import '../datasources/auth_remote_datasource.dart';

/// Orkestrasi login + sesi permanen (hapus hanya saat logout).
class AuthRepository {
  AuthRepository(this._remote, this._storage);

  final AuthRemoteDatasource _remote;
  final TokenStorage _storage;

  Future<AuthResponse> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    final result = await _remote.login(
      phoneOrEmail: phoneOrEmail,
      password: password,
    );
    if (result.token.isEmpty) {
      throw const FormatException('Token kosong dari server.');
    }
    await _storage.saveToken(result.token);
    await _storage.saveUser(
      id: result.user.id,
      name: result.user.name,
      role: result.user.role,
    );
    return result;
  }

  /// Cek sesi tersimpan: token ada + profil /me valid.
  /// Return null bila belum login / token basi.
  Future<User?> checkSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    try {
      final user = await _remote.me();
      await _storage.saveUser(id: user.id, name: user.name, role: user.role);
      return user;
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }

  Future<void> logout() async {
    await _remote.logout();
    await _storage.clearAll();
  }
}
