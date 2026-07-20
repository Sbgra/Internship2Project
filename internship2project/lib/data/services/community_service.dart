import '../../core/constants/api_constants.dart';
import '../models/community_model.dart';
import 'api_service.dart';

/// Topluluk API çağrılarını sarmalayan servis.
class CommunityService {
  CommunityService._();

  /// Topluluk listesi — herkes erişebilir.
  static Future<List<CommunityListItemModel>> listCommunities({
    int skip = 0,
    int limit = 20,
  }) async {
    final list = await ApiService.getList(
      '${ApiConstants.communitiesBase}?skip=$skip&limit=$limit',
    );
    return list
        .map((e) => CommunityListItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Topluluk detayı — herkes erişebilir, üyelik durumunu gösterir.
  static Future<CommunityDetailModel> getCommunityDetail(
    int communityId, {
    String? token,
  }) async {
    final data = await ApiService.get(
      ApiConstants.communityById(communityId),
      token: token,
    );
    return CommunityDetailModel.fromJson(data);
  }

  /// Topluluk oluştur — sadece üyeler.
  static Future<CommunityDetailModel> createCommunity({
    required String token,
    required String name,
    String? description,
  }) async {
    final data = await ApiService.post(
      ApiConstants.communitiesBase,
      {
        'name': name,
        if (description != null) 'description': description,
      },
      token: token,
    );
    return CommunityDetailModel.fromJson(data);
  }

  /// Topluluğa katıl — sadece üyeler.
  static Future<void> joinCommunity(int communityId, String token) async {
    await ApiService.post(
      ApiConstants.communityJoin(communityId),
      {},
      token: token,
    );
  }

  /// Topluluktan ayrıl — sadece üyeler.
  static Future<void> leaveCommunity(int communityId, String token) async {
    await ApiService.delete(
      ApiConstants.communityLeave(communityId),
      token: token,
    );
  }
}
