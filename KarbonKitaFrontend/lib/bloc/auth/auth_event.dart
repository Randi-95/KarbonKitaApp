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

/// Hapus token permanen + kembali ke login.
class LoggedOut extends AuthEvent {
  const LoggedOut();
}
