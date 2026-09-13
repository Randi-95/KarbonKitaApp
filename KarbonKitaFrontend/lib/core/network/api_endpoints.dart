/// Base URL & endpoint API KarbonKita.
///
/// Isi via --dart-define API_BASE_URL saat run/build.
/// Default localhost untuk Windows/Web, ganti ke 10.0.2.2 untuk emulator Android.
class ApiEndpoints {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/user';

  static String url(String path) => '$baseUrl$path';
}
