import 'package:image_picker/image_picker.dart';

/// Event AuthBloc.
sealed class AuthEvent {
  const AuthEvent();
}

/// Cek token tersimpan saat app dibuka (auto-login).
class SessionChecked extends AuthEvent {
  const SessionChecked();
}

/// Submit form login 1 field + password.
class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.phoneOrEmail, required this.password});

  final String phoneOrEmail;
  final String password;
}

/// Submit form register mitra (multipart + foto dokumen/toko).
class MitraRegisterSubmitted extends AuthEvent {
  const MitraRegisterSubmitted({required this.fields, required this.files});

  /// Field teks sesuai kontrak register-mitra (termasuk password_confirmation).
  final Map<String, dynamic> fields;

  /// File asli (bukan path string) agar web bisa kirim via bytes.
  /// Kunci: foto_ktp, foto_nib, foto_toko (wajib),
  /// foto_toko_2, foto_toko_3 (opsional/null).
  final Map<String, XFile?> files;
}

/// Hapus token permanen + kembali ke login.
class LoggedOut extends AuthEvent {
  const LoggedOut();
}
