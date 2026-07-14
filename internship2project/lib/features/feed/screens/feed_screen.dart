import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/article_model.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
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
    setState(() => _loadingRandom = true);
    try {
      final data = await ArticleService.getRandomFeed(limit: 10);
      if (mounted) setState(() => _randomFeed = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingRandom = false);
    }
  }

  Future<void> _loadPublic() async {
    setState(() => _loadingPublic = true);
    try {
      final data = await ArticleService.getPublicArticles(limit: 30);
      if (mounted) setState(() => _publicArticles = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inkwell'),
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
}
