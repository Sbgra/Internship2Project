import '../../core/constants/api_constants.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Makale ve kullanıcı profili API çağrılarını sarmalayan servis.
class ArticleService {
  ArticleService._();

  // ── Feed ───────────────────────────────────────────────────────

  static Future<List<ArticleModel>> getRandomFeed({int limit = 10}) async {
    final list = await ApiService.getList(
      '${ApiConstants.randomFeed}?limit=$limit',
    );
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Public Articles ────────────────────────────────────────────

  static Future<List<ArticleModel>> getPublicArticles({
    int skip = 0,
    int limit = 20,
  }) async {
    final list = await ApiService.getList(
      '${ApiConstants.publicArticles}?skip=$skip&limit=$limit',
    );
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ArticleDetailModel> getArticleById(
    int id, {
    String? token,
  }) async {
    final data = await ApiService.get(
      ApiConstants.articleById(id),
      token: token,
    );
    return ArticleDetailModel.fromJson(data);
  }

  // ── Auth Required ──────────────────────────────────────────────

  static Future<List<ArticleModel>> getMyArticles(String token) async {
    final list = await ApiService.getList(
      ApiConstants.myArticles,
      token: token,
    );
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ArticleDetailModel> createArticle({
    required String token,
    required String title,
    required String content,
    String? summary,
    bool isPublic = true,
  }) async {
    final data = await ApiService.post(
      ApiConstants.articlesBase,
      {
        'title': title,
        'content': content,
        if (summary != null) 'summary': summary,
        'is_public': isPublic,
      },
      token: token,
    );
    return ArticleDetailModel.fromJson(data);
  }

  static Future<ArticleDetailModel> updateArticle({
    required String token,
    required int articleId,
    String? title,
    String? content,
    String? summary,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (summary != null) 'summary': summary,
      if (isPublic != null) 'is_public': isPublic,
    };
    final data = await ApiService.put(
      ApiConstants.articleById(articleId),
      body,
      token: token,
    );
    return ArticleDetailModel.fromJson(data);
  }

  static Future<void> deleteArticle({
    required String token,
    required int articleId,
  }) async {
    await ApiService.delete(ApiConstants.articleById(articleId), token: token);
  }

  // ── User Profile ───────────────────────────────────────────────

  static Future<UserProfileModel> getUserProfile(int userId) async {
    final data = await ApiService.get(ApiConstants.userProfile(userId));
    return UserProfileModel.fromJson(data);
  }

  static Future<List<ArticleModel>> getUserArticles(int userId) async {
    final list = await ApiService.getList(ApiConstants.userArticles(userId));
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
