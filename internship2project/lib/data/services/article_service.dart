import '../../core/constants/api_constants.dart';
import '../models/article_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

/// Makale ve kullanıcı profili API çağrılarını sarmalayan servis.
class ArticleService {
  ArticleService._();

  // ── Feed ───────────────────────────────────────────────────────

  static Future<List<ArticleModel>> getRandomFeed({int limit = 10, List<String>? categories}) async {
    String url = '${ApiConstants.randomFeed}?limit=$limit';
    if (categories != null && categories.isNotEmpty) {
      for (var c in categories) {
        url += '&categories=${Uri.encodeComponent(c)}';
      }
    }
    final list = await ApiService.getList(url);
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Categories ──────────────────────────────────────────────────

  static Future<List<String>> getCategories() async {
    final list = await ApiService.getList(ApiConstants.categories);
    return list.map((e) => e.toString()).toList();
  }

  // ── Public Articles ────────────────────────────────────────────

  static Future<List<ArticleModel>> getPublicArticles({
    int skip = 0,
    int limit = 20,
    List<String>? categories,
  }) async {
    String url = '${ApiConstants.publicArticles}?skip=$skip&limit=$limit';
    if (categories != null && categories.isNotEmpty) {
      for (var c in categories) {
        url += '&categories=${Uri.encodeComponent(c)}';
      }
    }
    final list = await ApiService.getList(url);
    return list
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ArticleDetailModel> getArticleById(
    int id, {
    String? token,
    String? lang,
  }) async {
    String url = ApiConstants.articleById(id);
    if (lang != null && lang.isNotEmpty) {
      url += '?lang=${Uri.encodeComponent(lang)}';
    }
    final data = await ApiService.get(
      url,
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
    String? coverImage,
    bool isPublic = true,
    List<String>? categories,
    List<String>? targetLanguages,
  }) async {
    final data = await ApiService.post(
      ApiConstants.articlesBase,
      {
        'title': title,
        'content': content,
        if (summary != null) 'summary': summary,
        if (coverImage != null) 'cover_image': coverImage,
        'is_public': isPublic,
        if (categories != null) 'categories': categories,
        if (targetLanguages != null) 'target_languages': targetLanguages,
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
    String? coverImage,
    bool? isPublic,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (summary != null) 'summary': summary,
      if (coverImage != null) 'cover_image': coverImage,
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
