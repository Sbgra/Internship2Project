import 'dart:convert';
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
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getList(
    String url, {
    String? token,
  }) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    return _handleListResponse(response);
  }

  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client.put(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> patch(
    String url,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client.patch(
      Uri.parse(url),
      headers: _headers(token: token),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  static Future<void> delete(String url, {String? token}) async {
    final response = await _client.delete(
      Uri.parse(url),
      headers: _headers(token: token),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw ApiException(
        statusCode: response.statusCode,
        message: body['detail']?.toString() ?? 'Bir hata oluştu',
      );
    }
  }

  // ── Private helpers ────────────────────────────────────────────

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['detail']?.toString() ?? 'Bir hata oluştu',
    );
  }

  static List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    throw ApiException(
      statusCode: response.statusCode,
      message: body['detail']?.toString() ?? 'Bir hata oluştu',
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
