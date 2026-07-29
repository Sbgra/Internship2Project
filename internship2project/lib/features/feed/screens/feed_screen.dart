import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/article_model.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/article_card.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../core/theme/app_theme.dart';

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

  // Kategori filtresi
  List<String> _availableCategories = [];
  final List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadRandom();
    _loadPublic();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ArticleService.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories = cats;
        });
      }
    } catch (e) {
      debugPrint("Kategoriler yüklenemedi: $e");
    }
  }

  Future<void> _loadRandom() async {
    setState(() { _loadingRandom = true; _randomError = null; });
    try {
      final data = await ArticleService.getRandomFeed(
        limit: 10,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      );
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
      final data = await ArticleService.getPublicArticles(
        limit: 30,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
      );
      if (mounted) setState(() => _publicArticles = data);
    } on ApiException catch (e) {
      if (mounted) setState(() => _publicError = e.message);
    } catch (e) {
      if (mounted) setState(() => _publicError = 'Beklenmeyen hata: $e');
    } finally {
      if (mounted) setState(() => _loadingPublic = false);
    }
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kategoriler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() => _selectedCategories.clear());
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableCategories.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat, style: const TextStyle(fontSize: 14)),
                        selected: isSelected,
                        selectedColor: Colors.black12,
                        checkmarkColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                        backgroundColor: AppTheme.divider,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {}); // ana ekranı güncelle
                        _loadRandom();
                        _loadPublic();
                      },
                      child: const Text('Uygula'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyPlatform'),
        actions: [
          // Kategori filtre butonu
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showCategoryFilter,
                tooltip: 'Kategorilere Göre Filtrele',
              ),
              if (_selectedCategories.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.textPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_selectedCategories.length}',
                      style: const TextStyle(color: AppTheme.background, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
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
          labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          indicatorColor: AppTheme.textPrimary,
          indicatorWeight: 2,
          tabs: const [
            Tab(text: 'Sizin İçin'), // Keşfet yerine
            Tab(text: 'Takip Edilenler'), // Tümü yerine
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
      body: Column(
        children: [
          // Seçili kategorileri göster
          if (_selectedCategories.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppTheme.surface,
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _selectedCategories.map((cat) {
                  return Chip(
                    label: Text(cat, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    backgroundColor: AppTheme.divider,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onDeleted: () {
                      setState(() => _selectedCategories.remove(cat));
                      _loadRandom();
                      _loadPublic();
                    },
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: TabBarView(
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
            const Icon(Icons.error_outline, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary),
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

