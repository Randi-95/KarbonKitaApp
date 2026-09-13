import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'core/network/dio_client.dart';
import 'core/storage/token_storage.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'ui/screens/admin_validation_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/merchant_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = TokenStorage();
  final dioClient = DioClient(tokenReader: storage.readToken);
  final repository = AuthRepository(AuthRemoteDatasource(dioClient), storage);

  runApp(MyApp(authBloc: AuthBloc(repository)..add(const SessionChecked())));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: authBloc,
      child: MaterialApp(
        title: 'KarbonKita',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const _SessionGate(),
      ),
    );
  }
}

/// Auto-login: token permanen → langsung Home, tanpa token → Login.
class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.checking:
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            final role = state.user?.role ?? 'warga';
            if (role == 'mitra') return const MerchantDashboardScreen();
            if (role == 'admin') return const AdminValidationScreen();
            return const HomeScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
