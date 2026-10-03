import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/core/network/api_endpoints.dart';

// NOTE: tanpa --dart-define, baseUrl = 'http://localhost:8000/api'.
// resolveImageUrl menukar origin URL server ke origin tersebut.

void main() {
  group('ApiEndpoints.resolveImageUrl', () {
    test('null/kosong/tidak valid -> string kosong', () {
      expect(ApiEndpoints.resolveImageUrl(null), '');
      expect(ApiEndpoints.resolveImageUrl(''), '');
      expect(ApiEndpoints.resolveImageUrl('   '), '');
    });

    test('APP_URL tanpa port diperbaiki ke port baseUrl', () {
      expect(
        ApiEndpoints.resolveImageUrl(
          'http://localhost/storage/mitra/21/foto.png',
        ),
        'http://localhost:8000/storage/mitra/21/foto.png',
      );
    });

    test('path relatif digabung ke origin baseUrl', () {
      expect(
        ApiEndpoints.resolveImageUrl('/storage/mitra/21/foto.png'),
        'http://localhost:8000/storage/mitra/21/foto.png',
      );
      expect(
        ApiEndpoints.resolveImageUrl('storage/mitra/21/foto.png'),
        'http://localhost:8000/storage/mitra/21/foto.png',
      );
    });

    test('URL yang sudah benar tidak berubah', () {
      const url = 'http://localhost:8000/storage/mitra/21/foto.png';
      expect(ApiEndpoints.resolveImageUrl(url), url);
    });

    test('query string dipertahankan', () {
      expect(
        ApiEndpoints.resolveImageUrl('http://localhost/storage/x.png?sig=abc'),
        'http://localhost:8000/storage/x.png?sig=abc',
      );
    });
  });
}
