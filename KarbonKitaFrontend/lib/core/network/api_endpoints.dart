/// Base URL & endpoint API KarbonKita.
///
/// Isi via --dart-define API_BASE_URL saat run/build.
/// Default localhost untuk Windows/Web, ganti ke 10.0.2.2 untuk emulator Android.
class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/user';

  // Missions
  static const String missionsActive = '/missions/active';
  static const String verifyWaste = '/missions/verify-waste';
  static const String mobilitySync = '/missions/mobility-sync';

  // Saga (Quiz)
  static const String sagaQuizzes = '/saga/quizzes';
  static const String sagaAnswer = '/saga/answer';

  // Marketplace (Voucher)
  static const String vouchers = '/vouchers';

  // Dashboard (saldo eco_points)
  static const String userDashboard = '/user/dashboard';

  static String url(String path) => '$baseUrl$path';
}
