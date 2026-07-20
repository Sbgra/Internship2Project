import '../../core/constants/api_constants.dart';
import '../models/stats_model.dart';
import 'api_service.dart';

/// Makale istatistik ve alkış API çağrılarını sarmalayan servis.
class StatsService {
  StatsService._();

  /// Makale istatistiklerini getirir — herkes erişebilir.
  static Future<ArticleStatsModel> getArticleStats(int articleId) async {
    final data = await ApiService.get(ApiConstants.articleStats(articleId));
    return ArticleStatsModel.fromJson(data);
  }

  /// Makale görüntülenme sayacını artırır — herkes çağırabilir.
  static Future<void> recordView(int articleId) async {
    await ApiService.post(ApiConstants.articleView(articleId), {});
  }

  /// Makaleye alkış atar — herkes (makale başına 50 limit).
  static Future<ClapResultModel> clap(
    int articleId,
    int count, {
    String? token,
  }) async {
    final data = await ApiService.post(
      ApiConstants.articleClap(articleId),
      {'count': count},
      token: token,
    );
    return ClapResultModel.fromJson(data);
  }

  /// Makalenin alkış bilgilerini getirir — herkes erişebilir.
  static Future<ClapResultModel> getClaps(
    int articleId, {
    String? token,
  }) async {
    final data = await ApiService.get(
      ApiConstants.articleClaps(articleId),
      token: token,
    );
    return ClapResultModel.fromJson(data);
  }
}
