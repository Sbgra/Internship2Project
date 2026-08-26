import '../../core/constants/api_constants.dart';
import 'api_service.dart';

/// AI işlemlerini (makale oluşturma, asistan sohbeti vb.) yürüten servis.
class AIService {
  AIService._();

  /// Yapay zeka ile makale taslağı oluşturur.
  static Future<Map<String, dynamic>> generateArticle({
    required String token,
    required String prompt,
    required String language,
  }) async {
    final data = await ApiService.post(
      ApiConstants.aiGenerateArticle,
      {
        'prompt': prompt,
        'language': language,
      },
      token: token,
    );
    return data;
  }

  /// AI Asistan ile sohbet eder. Editördeki mevcut yazıyı context olarak gönderir.
  static Future<Map<String, dynamic>> chat({
    required String token,
    required String contextText,
    required List<Map<String, dynamic>> messages,
  }) async {
    final data = await ApiService.post(
      ApiConstants.aiChat,
      {
        'context': contextText,
        'messages': messages,
      },
      token: token,
    );
    return data;
  }
}
