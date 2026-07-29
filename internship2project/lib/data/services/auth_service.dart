import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/token_storage.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Auth durumunu tüm uygulamaya yayan ChangeNotifier.
/// Provider aracılığıyla widget ağacına enjekte edilir.
class AuthService extends ChangeNotifier {
  String? _token;
  UserPublicModel? _currentUser;
  bool _initialized = false;

  String? get token => _token;
  UserPublicModel? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;
  bool get initialized => _initialized;

  /// Uygulama başlangıcında kaydedilmiş token varsa yükler. (Otomatik giriş isteğe bağlı olarak iptal edildi)
  Future<void> init() async {
    // Otomatik giriş kapatıldı: Uygulama her açıldığında token silinsin
    await TokenStorage.clear();
    _token = null;
    
    if (_token != null) {
      try {
        final data = await ApiService.get(
          ApiConstants.myProfile,
          token: _token,
        );
        _currentUser = UserPublicModel.fromJson(data);
      } catch (_) {
        // Token geçersizse temizle
        await _clearSession();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await ApiService.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> register(String username, String email, String password) async {
    final data = await ApiService.post(ApiConstants.register, {
      'username': username,
      'email': email,
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> logout() async {
    await _clearSession();
    notifyListeners();
  }

  Future<void> updateBio(String bio) async {
    if (_token == null) return;
    final data = await ApiService.patch(
      ApiConstants.updateBio,
      {'bio': bio},
      token: _token,
    );
    _currentUser = UserPublicModel.fromJson(data);
    notifyListeners();
  }

  Future<void> updateProfileCustomization(String? profilePicture) async {
    if (_token == null) return;
    final data = await ApiService.patch(
      ApiConstants.updateProfileCustomization,
      {'profile_picture': profilePicture},
      token: _token,
    );
    _currentUser = UserPublicModel.fromJson(data);
    notifyListeners();
  }

  // ── Private ────────────────────────────────────────────────────

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['access_token'] as String;
    _currentUser = UserPublicModel.fromJson(
      data['user'] as Map<String, dynamic>,
    );
    await TokenStorage.save(_token!);
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _token = null;
    _currentUser = null;
    await TokenStorage.clear();
  }
}
