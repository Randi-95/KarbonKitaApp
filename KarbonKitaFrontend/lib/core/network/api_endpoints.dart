/// Base URL & endpoint API KarbonKita.
///
/// Isi via --dart-define API_BASE_URL saat run/build.
/// Default localhost untuk Windows/Web, ganti ke 10.0.2.2 untuk emulator Android.
class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mage.pemudasintaks.web.id/api',
  );

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String me = '/user';

  // Missions
  static const String missionsActive = '/missions/active';
  static const String verifyWaste = '/missions/verify-waste';
  static const String mobilitySync = '/missions/mobility-sync';

  // Saga (Quiz)
  static const String sagaNodes = '/saga/nodes';
  static const String sagaQuizzes = '/saga/quizzes';
  static const String sagaAnswer = '/saga/answer';

  static String sagaNodeQuestions(int missionId) =>
      '$sagaNodes/$missionId/questions';

  // Marketplace (Voucher)
  static const String vouchers = '/vouchers';
  static const String vouchersClaim = '/vouchers/claim';
  static const String myVouchers = '/user/my-vouchers';

  /// GET /api/vouchers, opsional filter `?category=kuliner|...`.
  static String vouchersQuery({String? category}) =>
      category == null ? vouchers : '$vouchers?category=$category';

  // Dashboard (saldo eco_points)
  static const String userDashboard = '/user/dashboard';

  // Level tiers (3 tier lencana untuk Profil)
  static const String userLevels = '/user/levels';

  // Aktivitas terbaru untuk Profil
  static const String userActivities = '/user/activities';

  // Leaderboard (scope: rt|rw, timeframe: weekly|monthly)
  static const String leaderboard = '/leaderboard';

  // Merchant (Mitra UMKM) — role:mitra
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantStatus = '/merchant/status';
  static const String merchantDisbursements = '/merchant/disbursements';

  // Redeem voucher oleh kasir (QR scan / input manual token).
  // Body: {unique_code: qr_token}. Token asli backend format KBK-XXX-XXX.
  static const String vouchersRedeem = '/vouchers/redeem';

  static String leaderboardQuery({
    required String scope,
    required String timeframe,
  }) => '$leaderboard?scope=$scope&timeframe=$timeframe';

  static String url(String path) => '$baseUrl$path';
}
