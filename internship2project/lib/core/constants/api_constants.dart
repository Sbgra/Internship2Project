// Tüm API endpoint URL'leri burada merkezi olarak yönetilir.
// Sadece bu dosyayı değiştirerek tüm servisleri güncellemiş olursunuz.

class ApiConstants {
  ApiConstants._(); // instantiate edilemez

  // Android emülatör için 10.0.2.2, Web/Desktop/iOS Sim. için 127.0.0.1 (veya localhost) kullanın.
  static const String baseUrl = 'http://10.0.2.2:8000'; // Web/Desktop için

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  // Articles
  static const String publicArticles = '$baseUrl/articles/public';
  static const String categories = '$baseUrl/articles/categories';
  static const String articlesBase = '$baseUrl/articles';
  static const String myArticles = '$baseUrl/articles/my';
  static String articleById(int id) => '$baseUrl/articles/$id';

  // Feed
  static const String randomFeed = '$baseUrl/feed/random';

  // Users
  static String userProfile(int id) => '$baseUrl/users/$id/profile';
  static String userArticles(int id) => '$baseUrl/users/$id/articles';
  static const String myProfile = '$baseUrl/users/me/profile';
  static const String updateBio = '$baseUrl/users/me/bio';
  static const String updateProfileCustomization =
      '$baseUrl/users/me/profile_customization';

  // Stats — herkes erişebilir
  static String articleStats(int id) => '$baseUrl/stats/$id';
  static String articleView(int id) => '$baseUrl/stats/$id/view';

  // Claps — herkes kullanabilir (makale başına 50 limit)
  static String articleClap(int id) => '$baseUrl/articles/$id/clap';
  static String articleClaps(int id) => '$baseUrl/articles/$id/claps';

  // Communities — listeleme herkese, katılma/oluşturma üyelere
  static const String communitiesBase = '$baseUrl/communities';
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
  static const String magazinesBase = '$baseUrl/magazines';
  static const String myMagazines = '$baseUrl/magazines/my';
  static String magazineById(int id) => '$baseUrl/magazines/$id';
  static String magazineArticles(int id) => '$baseUrl/magazines/$id/articles';
  static String magazineRemoveArticle(int magId, int artId) =>
      '$baseUrl/magazines/$magId/articles/$artId';

  // Settings — sadece üyeler
  static const String mySettings = '$baseUrl/settings/me';

  // Media
  static const String mediaUploadImage = '$baseUrl/media/upload/image';
}
