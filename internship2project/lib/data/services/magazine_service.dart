import '../../core/constants/api_constants.dart';
import '../models/magazine_model.dart';
import 'api_service.dart';

/// Dijital dergi API çağrılarını sarmalayan servis.
class MagazineService {
  MagazineService._();

  /// Kendi dergilerimi listele — sadece üyeler.
  static Future<List<MagazineModel>> getMyMagazines(String token) async {
    final list = await ApiService.getList(
      ApiConstants.myMagazines,
      token: token,
    );
    return list
        .map((e) => MagazineModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Dergi detayı — herkes erişebilir.
  static Future<MagazineDetailModel> getMagazineDetail(int magazineId) async {
    final data = await ApiService.get(ApiConstants.magazineById(magazineId));
    return MagazineDetailModel.fromJson(data);
  }

  /// Dergi oluştur — sadece üyeler.
  static Future<MagazineModel> createMagazine({
    required String token,
    required String title,
    String? description,
  }) async {
    final data = await ApiService.post(
      ApiConstants.magazinesBase,
      {
        'title': title,
        if (description != null) 'description': description,
      },
      token: token,
    );
    return MagazineModel.fromJson(data);
  }

  /// Dergiye makale ekle — sadece dergi sahibi.
  static Future<void> addArticle({
    required String token,
    required int magazineId,
    required int articleId,
  }) async {
    await ApiService.post(
      ApiConstants.magazineArticles(magazineId),
      {'article_id': articleId},
      token: token,
    );
  }

  /// Dergiden makale çıkar — sadece dergi sahibi.
  static Future<void> removeArticle({
    required String token,
    required int magazineId,
    required int articleId,
  }) async {
    await ApiService.delete(
      ApiConstants.magazineRemoveArticle(magazineId, articleId),
      token: token,
    );
  }
}
