import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<SessionChecked>(_onSessionChecked);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<MitraRegisterSubmitted>(_onMitraRegisterSubmitted);
    on<LoggedOut>(_onLoggedOut);
  }

  final AuthRepository _repository;

  Future<void> _onSessionChecked(
    SessionChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.checking));
    final user = await _repository.checkSession();
    if (user != null) {
      emit(AuthState(status: AuthStatus.authenticated, user: user));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    final phoneOrEmail = event.phoneOrEmail.trim();
    if (phoneOrEmail.isEmpty || event.password.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          message: 'No HP/Email dan kata sandi wajib diisi.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await _repository.login(
        phoneOrEmail: phoneOrEmail,
        password: event.password,
      );
      emit(AuthState(status: AuthStatus.authenticated, user: result.user));
    } on AuthException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: e.message,
          fieldErrors: e.errors,
        ),
      );
    } on FormatException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, message: e.message));
    } catch (_) {
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          message: 'Terjadi kesalahan. Coba lagi.',
        ),
      );
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    await _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onMitraRegisterSubmitted(
    MitraRegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.status == AuthStatus.loading) return;
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final result = await _repository.registerMitra(
        fields: event.fields,
        files: event.files,
      );
      // Token sudah disimpan repository → langsung authenticated (pending).
      emit(AuthState(status: AuthStatus.authenticated, user: result.user));
    } on AuthException catch (e) {
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: e.message,
          fieldErrors: e.errors,
        ),
      );
    } on FormatException catch (e) {
      emit(AuthState(status: AuthStatus.unauthenticated, message: e.message));
    } catch (e) {
      // Error non-Dio (mis. file tak terbaca) — catat detailnya agar
      // diagnosis tidak buta; user tetap dapat pesan generik yang aman.
      debugPrint('[mitra-register] unexpected: ${e.runtimeType}: $e');
      emit(
        AuthState(
          status: AuthStatus.unauthenticated,
          message: kDebugMode
              ? 'Pendaftaran gagal (${e.runtimeType}). Coba lagi.'
              : 'Pendaftaran gagal. Coba lagi.',
        ),
      );
    }
  }
}
