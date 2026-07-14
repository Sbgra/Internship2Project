// Tüm API endpoint URL'leri burada merkezi olarak yönetilir.
// Sadece bu dosyayı değiştirerek tüm servisleri güncellemiş olursunuz.

class ApiConstants {
  ApiConstants._(); // instantiate edilemez

  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emülatör için
  // static const String baseUrl = 'http://localhost:8000'; // Web/Desktop için

  // Auth
  static const String register = '$baseUrl/auth/register';
  static const String login = '$baseUrl/auth/login';

  // Articles
  static const String publicArticles = '$baseUrl/articles/public';
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
}
