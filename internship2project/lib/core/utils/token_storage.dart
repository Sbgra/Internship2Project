import 'package:shared_preferences/shared_preferences.dart';

/// JWT token'ı cihazda güvenli biçimde saklar ve okur.
/// Auth servisi bu sınıfı kullanır, widget'lar doğrudan erişmez.
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
