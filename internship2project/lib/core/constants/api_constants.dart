import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Tüm API endpoint URL'leri burada merkezi olarak yönetilir.
// Sadece bu dosyayı değiştirerek tüm servisleri güncellemiş olursunuz.

class ApiConstants {
  ApiConstants._(); // instantiate edilemez

  // Android emülatör için 10.0.2.2, Web/Desktop/iOS Sim. için 127.0.0.1 kullanır.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // Auth
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';

  // Articles
  static String get publicArticles => '$baseUrl/articles/public';
  static String get categories => '$baseUrl/articles/categories';
  static String get articlesBase => '$baseUrl/articles';
  static String get myArticles => '$baseUrl/articles/my';
  static String articleById(int id) => '$baseUrl/articles/$id';

  // Feed
  static String get randomFeed => '$baseUrl/feed/random';

  // Users
  static String userProfile(int id) => '$baseUrl/users/$id/profile';
  static String userArticles(int id) => '$baseUrl/users/$id/articles';
  static String get myProfile => '$baseUrl/users/me/profile';
  static String get updateBio => '$baseUrl/users/me/bio';
  static String get updateProfileCustomization =>
      '$baseUrl/users/me/profile_customization';

  // Stats — herkes erişebilir
  static String articleStats(int id) => '$baseUrl/stats/$id';
  static String articleView(int id) => '$baseUrl/stats/$id/view';

  // Claps — herkes kullanabilir (makale başına 50 limit)
  static String articleClap(int id) => '$baseUrl/articles/$id/clap';
  static String articleClaps(int id) => '$baseUrl/articles/$id/claps';

  // Communities — listeleme herkese, katılma/oluşturma üyelere
  static String get communitiesBase => '$baseUrl/communities';
  static String communityById(int id) => '$baseUrl/communities/$id';
  static String communityJoin(int id) => '$baseUrl/communities/$id/join';
  static String communityLeave(int id) => '$baseUrl/communities/$id/leave';
  static String communityForumTopics(int id) =>
      '$baseUrl/communities/$id/forum';
  static String communityForumTopicDetails(int topicId) =>
      '$baseUrl/communities/forum/$topicId';
  static String communityForumTopicPosts(int topicId) =>
      '$baseUrl/communities/forum/$topicId/posts';

  // Magazines — oluşturma/düzenleme üyelere, detay herkese
  static String get magazinesBase => '$baseUrl/magazines';
  static String get myMagazines => '$baseUrl/magazines/my';
  static String magazineById(int id) => '$baseUrl/magazines/$id';
  static String magazineArticles(int id) => '$baseUrl/magazines/$id/articles';
  static String magazineRemoveArticle(int magId, int artId) =>
      '$baseUrl/magazines/$magId/articles/$artId';

  // Settings — sadece üyeler
  static String get mySettings => '$baseUrl/settings/me';

  // AI
  static String get aiGenerateArticle => '$baseUrl/ai/generate-article';
  static String get aiChat => '$baseUrl/ai/chat';

  // Media
  static String get mediaUploadImage => '$baseUrl/media/upload/image';
  static String get mediaUploadAudio => '$baseUrl/media/upload/audio';
}

