import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/article_model.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/article_card.dart';
import '../../../shared/widgets/app_drawer.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<ArticleModel> _randomFeed = [];
  List<ArticleModel> _publicArticles = [];
  bool _loadingRandom = true;
  bool _loadingPublic = true;
  String? _randomError;
  String? _publicError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRandom();
    _loadPublic();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRandom() async {
    setState(() { _loadingRandom = true; _randomError = null; });
    try {
      final data = await ArticleService.getRandomFeed(limit: 10);
      if (mounted) setState(() => _randomFeed = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _randomError = e.message);
    } catch (e) {
      if (mounted) setState(() => _randomError = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _loadingRandom = false);
    }
  }

  Future<void> _loadPublic() async {
    setState(() { _loadingPublic = true; _publicError = null; });
    try {
      final data = await ArticleService.getPublicArticles(limit: 30);
      if (mounted) setState(() => _publicArticles = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _publicError = e.message);
    } catch (e) {
      if (mounted) setState(() => _publicError = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPlatform'),
        actions: [
          if (!auth.isLoggedIn)
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/login'),
              child: const Text('Giriş'),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context)
                  .pushNamed('/profile', arguments: auth.currentUser!.id),
              child: Text(auth.currentUser!.username),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Keşfet'),
            Tab(text: 'Tümü'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed('/create-article'),
              child: const Icon(Icons.edit),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Rastgele akış
          _loadingRandom
              ? const LoadingIndicator()
              : _randomError != null
                  ? _buildErrorView(_randomError!, _loadRandom)
                  : RefreshIndicator(
                      onRefresh: _loadRandom,
                      child: _randomFeed.isEmpty
                          ? const Center(child: Text('Henüz makale yok'))
                          : ListView.builder(
                              itemCount: _randomFeed.length,
                              itemBuilder: (context, i) => ArticleCard(
                                article: _randomFeed[i],
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/article',
                                  arguments: _randomFeed[i].id,
                                ),
                              ),
                            ),
                    ),

          // Tüm public makaleler
          _loadingPublic
              ? const LoadingIndicator()
              : _publicError != null
                  ? _buildErrorView(_publicError!, _loadPublic)
                  : RefreshIndicator(
                      onRefresh: _loadPublic,
                      child: _publicArticles.isEmpty
                          ? const Center(child: Text('Henüz makale yok'))
                          : ListView.builder(
                              itemCount: _publicArticles.length,
                              itemBuilder: (context, i) => ArticleCard(
                                article: _publicArticles[i],
                                onTap: () => Navigator.of(context).pushNamed(
                                  '/article',
                                  arguments: _publicArticles[i].id,
                                ),
                              ),
                            ),
                    ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
