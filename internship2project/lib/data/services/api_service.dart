import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// HTTP istek/yanıt işlemlerini merkezi olarak yönetir.
/// Tüm servisler bu sınıfı kullanır; doğrudan http paketi çağırmazlar.
class ApiService {
  ApiService._();

  static final _client = http.Client();

  static Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(
    String url, {
    String? token,
  }) async {
    final response = await _safeRequest(() => _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    ));
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getList(
    String url, {
    String? token,
  }) async {
    final response = await _safeRequest(() => _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    ));
    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _safeRequest(() => _client.post(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
    ));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _safeRequest(() => _client.put(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
    ));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _safeRequest(() => _client.patch(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
    ));
    return _handleResponse(response);
  }

  static Future<void> delete(String url, {String? token}) async {
    final response = await _safeRequest(() => _client.delete(
      Uri.parse(url),
      headers: _headers(token: token),
    ));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractErrorMessage(response),
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────

  /// Ağ hatalarını (timeout, bağlantı kopması) yakalayıp ApiException'a çevirir.
  static Future<http.Response> _safeRequest(
    Future<http.Response> Function() request,
  ) async {
    try {
      return await request();
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Sunucuya bağlanılamıyor. İnternet bağlantınızı kontrol edin.',
      );
    } on HttpException {
      throw const ApiException(
        statusCode: 0,
        message: 'Sunucuyla iletişim kurulamadı.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        message: 'Sunucu geçersiz bir yanıt döndürdü.',
      );
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Beklenmeyen bağlantı hatası: ${e.runtimeType}',
      );
    }
  }

  /// JSON yanıtından insan-okunabilir hata mesajı çıkarır.
  /// Pydantic 422 hatalarını ve standart FastAPI detail alanını destekler.
  static String _extractErrorMessage(http.Response response) {
    try {
      final raw = utf8.decode(response.bodyBytes);
      if (raw.isEmpty) {
        return _defaultErrorForCode(response.statusCode);
      }

      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];

        // Standart FastAPI hata mesajı: {"detail": "Hatalı e-posta veya şifre"}
        if (detail is String) {
          return detail;
        }

        // Pydantic validation hatası: {"detail": [{"loc": [...], "msg": "...", "type": "..."}]}
        if (detail is List && detail.isNotEmpty) {
          final messages = detail.map((e) {
            if (e is Map<String, dynamic>) {
              final loc = e['loc'] as List<dynamic>?;
              final msg = e['msg'] as String? ?? 'Geçersiz değer';
              final field = loc != null && loc.length > 1
                  ? loc.last.toString()
                  : 'alan';
              return '$field: $msg';
            }
            return e.toString();
          }).toList();
          return messages.join('\n');
        }

        // Diğer detail formatı
        if (detail != null) {
          return detail.toString();
        }
      }

      return _defaultErrorForCode(response.statusCode);
    } catch (_) {
      return _defaultErrorForCode(response.statusCode);
    }
  }

  /// HTTP durum koduna göre varsayılan Türkçe hata mesajı.
  static String _defaultErrorForCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Geçersiz istek.';
      case 401:
        return 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
      case 403:
        return 'Bu işlem için yetkiniz yok.';
      case 404:
        return 'Aradığınız içerik bulunamadı.';
      case 409:
        return 'Bu kayıt zaten mevcut.';
      case 422:
        return 'Girdiğiniz bilgiler geçersiz. Lütfen kontrol edin.';
      case 429:
        return 'Çok fazla istek gönderdiniz. Lütfen biraz bekleyin.';
      case 500:
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      case 0:
        return 'Bağlantı hatası.';
      default:
        return 'Bir hata oluştu (kod: $statusCode).';
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } on FormatException {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Sunucu geçersiz bir yanıt döndürdü.',
        );
      }
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(response),
    );
  }

  static List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      } on FormatException {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Sunucu geçersiz bir yanıt döndürdü.',
        );
      }
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _extractErrorMessage(response),
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
