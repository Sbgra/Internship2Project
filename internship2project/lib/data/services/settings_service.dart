import '../../core/constants/api_constants.dart';
import 'api_service.dart';

/// Kullanıcı ayarları API çağrılarını sarmalayan servis.
class SettingsService {
  SettingsService._();

  /// Ayarları getir — sadece üyeler.
  static Future<Map<String, dynamic>> getMySettings(String token) async {
    return await ApiService.get(ApiConstants.mySettings, token: token);
  }

  /// Ayarları güncelle — sadece üyeler.
  static Future<Map<String, dynamic>> updateMySettings({
    required String token,
    String? appIcon,
  }) async {
    return await ApiService.patch(
      ApiConstants.mySettings,
      {
        if (appIcon != null) 'app_icon': appIcon,
      },
      token: token,
    );
  }
}
