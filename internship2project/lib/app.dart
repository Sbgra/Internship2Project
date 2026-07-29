import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/articles/screens/article_detail_screen.dart';
import 'features/articles/screens/create_article_screen.dart';
import 'features/articles/screens/offline_articles_screen.dart';
import 'features/profile/screens/author_profile_screen.dart';
import 'features/communities/screens/communities_screen.dart';
import 'features/communities/screens/community_detail_screen.dart';
import 'features/communities/screens/create_community_screen.dart';
import 'features/magazines/screens/magazines_screen.dart';
import 'features/magazines/screens/magazine_detail_screen.dart';
import 'features/magazines/screens/create_magazine_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/settings/screens/app_icon_settings_screen.dart';
import 'shared/widgets/loading_indicator.dart';

/// Uygulamanın kök widget'ı.
/// Provider, tema ve routing burada tanımlanır.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..init(),
      child: MaterialApp(
        title: 'MyPlatform',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppGate(),
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const FeedScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case '/create-article':
        return MaterialPageRoute(builder: (_) => const CreateArticleScreen());
      case '/article':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => ArticleDetailScreen(articleId: id),
        );
      case '/profile':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => AuthorProfileScreen(userId: id),
        );
      // Çevrimdışı makaleler — sadece üyeler
      case '/offline-articles':
        return MaterialPageRoute(
            builder: (_) => const OfflineArticlesScreen());
      // Topluluklar
      case '/communities':
        return MaterialPageRoute(
            builder: (_) => const CommunitiesScreen());
      case '/community':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(communityId: id),
        );
      case '/create-community':
        return MaterialPageRoute(
            builder: (_) => const CreateCommunityScreen());
      // Dergiler — sadece üyeler
      case '/magazines':
        return MaterialPageRoute(builder: (_) => const MagazinesScreen());
      case '/magazine':
        final id = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => MagazineDetailScreen(magazineId: id),
        );
      case '/create-magazine':
        return MaterialPageRoute(
            builder: (_) => const CreateMagazineScreen());
      // Ayarlar — sadece üyeler
      case '/settings/icon':
        return MaterialPageRoute(
            builder: (_) => const AppIconSettingsScreen());
      case '/edit-profile':
        return MaterialPageRoute(
            builder: (_) => const EditProfileScreen());
      default:
        return MaterialPageRoute(builder: (_) => const FeedScreen());
    }
  }
}

/// AuthService.init() tamamlanana kadar splash/loading gösterir.
class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (!auth.initialized) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: LoadingIndicator(message: 'Yükleniyor...'),
      );
    }
    return const FeedScreen();
  }
}
