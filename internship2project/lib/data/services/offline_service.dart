import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article_model.dart';

/// Çevrimdışı makale okuma servisi.
/// Makaleleri SharedPreferences'a JSON olarak kaydeder.
/// Sadece üyeler bu özelliği kullanabilir.
class OfflineService {
  OfflineService._();

  static const _offlineKey = 'offline_articles';

  /// Makaleyi çevrimdışı olarak kaydet.
  static Future<void> saveArticle(ArticleDetailModel article) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedArticles();

    // Zaten kaydedildiyse güncelle
    final index = list.indexWhere((a) => a.id == article.id);
    if (index >= 0) {
      list[index] = article;
    } else {
      list.add(article);
    }

    final jsonList = list.map((a) => _articleToJson(a)).toList();
    await prefs.setString(_offlineKey, jsonEncode(jsonList));
  }

  /// Kayıtlı makaleyi sil.
  static Future<void> removeArticle(int articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getSavedArticles();
    list.removeWhere((a) => a.id == articleId);
    final jsonList = list.map((a) => _articleToJson(a)).toList();
    await prefs.setString(_offlineKey, jsonEncode(jsonList));
  }

  /// Tüm kayıtlı makaleleri getir.
  static Future<List<ArticleDetailModel>> getSavedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_offlineKey);
    if (raw == null || raw.isEmpty) return [];
    final jsonList = jsonDecode(raw) as List<dynamic>;
    return jsonList
        .map((e) => ArticleDetailModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Makale kaydedilmiş mi kontrol et.
  static Future<bool> isArticleSaved(int articleId) async {
    final list = await getSavedArticles();
    return list.any((a) => a.id == articleId);
  }

  /// ArticleDetailModel → JSON map.
  static Map<String, dynamic> _articleToJson(ArticleDetailModel a) {
    return {
      'id': a.id,
      'title': a.title,
      'summary': a.summary,
      'is_public': a.isPublic,
      'author_id': a.authorId,
      'created_at': a.createdAt.toIso8601String(),
      'content': a.content,
      'updated_at': a.updatedAt?.toIso8601String(),
      'author': {
        'id': a.author.id,
        'username': a.author.username,
        'bio': a.author.bio,
        'profile_picture': a.author.profilePicture,
        'profile_color': a.author.profileColor,
        'emotes': a.author.emotes,
        'created_at': a.author.createdAt.toIso8601String(),
      },
    };
  }
}
