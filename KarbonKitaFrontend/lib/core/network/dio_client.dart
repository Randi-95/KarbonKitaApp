import 'package:dio/dio.dart';

import 'api_endpoints.dart';
import 'auth_exception.dart';

typedef TokenReader = Future<String?> Function();

/// Dio terpusat untuk KarbonKita.
///
/// - Base URL dari [ApiEndpoints].
/// - Attach `Authorization: Bearer` bila token tersedia.
/// - Mapping status backend ke [AuthException] yang ramah UI.
class DioClient {
  DioClient({Dio? dio, TokenReader? tokenReader})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiEndpoints.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ),
      _tokenReader = tokenReader {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenReader?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenReader? _tokenReader;

  Dio get dio => _dio;

  /// POST helper yang melempar [AuthException] dengan pesan siap tampil.
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post(path, data: body);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await _dio.get(path);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return <String, dynamic>{'data': data};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  AuthException _map(DioException e) {
    final status = e.response?.statusCode;
    final body = e.response?.data;

    String message = 'Terjadi kesalahan jaringan. Coba lagi.';
    var errors = const <String, List<String>>{};

    if (body is Map) {
      final rawMsg = body['message'];
      if (rawMsg is String && rawMsg.isNotEmpty) message = rawMsg;
      final rawErrors = body['errors'];
      if (rawErrors is Map) {
        final parsed = <String, List<String>>{};
        rawErrors.forEach((key, value) {
          if (value is List) {
            parsed[key.toString()] = value.map((v) => v.toString()).toList();
          } else if (value != null) {
            parsed[key.toString()] = [value.toString()];
          }
        });
        errors = parsed;
      }
    }

    switch (status) {
      case 401:
        return AuthException(
          'No HP/Email atau kata sandi salah.',
          errors: errors,
          statusCode: status,
        );
      case 403:
        return AuthException(
          message.isNotEmpty
              ? message
              : 'Akun dinonaktifkan. Hubungi dukungan.',
          errors: errors,
          statusCode: status,
        );
      case 422:
        return AuthException(
          message.isNotEmpty ? message : 'Data belum valid. Periksa kembali.',
          errors: errors,
          statusCode: status,
        );
      case 429:
        return AuthException(
          'Terlalu sering mencoba. Tunggu 1 menit lalu coba lagi.',
          errors: errors,
          statusCode: status,
        );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const AuthException(
        'Tidak dapat terhubung ke server. Periksa koneksi.',
      );
    }

    return AuthException(message, errors: errors, statusCode: status);
  }
}
