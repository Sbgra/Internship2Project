import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/feed/screens/feed_screen.dart';
import 'features/articles/screens/article_detail_screen.dart';
import 'features/articles/screens/create_article_screen.dart';
import 'features/profile/screens/author_profile_screen.dart';
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
        title: 'Inkwell',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
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
