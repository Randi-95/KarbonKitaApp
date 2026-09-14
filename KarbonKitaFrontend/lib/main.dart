import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/mission/mission_bloc.dart';
import 'bloc/voucher/voucher_bloc.dart';
import 'core/network/dio_client.dart';
import 'core/storage/token_storage.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/mission_remote_datasource.dart';
import 'data/datasources/voucher_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/mission_repository.dart';
import 'data/repositories/voucher_repository.dart';
import 'ui/screens/admin_validation_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/merchant_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = TokenStorage();
  final dioClient = DioClient(tokenReader: storage.readToken);
  final authRepository = AuthRepository(AuthRemoteDatasource(dioClient), storage);
  final missionRepository = MissionRepository(MissionRemoteDatasource(dioClient));
  final voucherRepository = VoucherRepository(VoucherRemoteDatasource(dioClient));

  final authBloc = AuthBloc(authRepository)..add(const SessionChecked());
  final missionBloc = MissionBloc(missionRepository);
  final voucherBloc = VoucherBloc(voucherRepository);

  runApp(MyApp(authBloc: authBloc, missionBloc: missionBloc, voucherBloc: voucherBloc));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.authBloc, required this.missionBloc, required this.voucherBloc});

  final AuthBloc authBloc;
  final MissionBloc missionBloc;
  final VoucherBloc voucherBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: missionBloc),
        BlocProvider.value(value: voucherBloc),
      ],
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
