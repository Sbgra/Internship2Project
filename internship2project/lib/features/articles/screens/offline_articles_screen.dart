import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/article_model.dart';
import '../../../data/services/offline_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Çevrimdışı kaydedilmiş makaleler ekranı — sadece üyeler.
class OfflineArticlesScreen extends StatefulWidget {
  const OfflineArticlesScreen({super.key});

  @override
  State<OfflineArticlesScreen> createState() => _OfflineArticlesScreenState();
}

class _OfflineArticlesScreenState extends State<OfflineArticlesScreen> {
  List<ArticleDetailModel> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final articles = await OfflineService.getSavedArticles();
    if (mounted) {
      setState(() {
        _articles = articles;
        _loading = false;
      });
    }
  }

  Future<void> _remove(int articleId) async {
    await OfflineService.removeArticle(articleId);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Makale çevrimdışı listesinden kaldırıldı'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Çevrimdışı Makaleler')),
      body: _loading
          ? const LoadingIndicator()
          : _articles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 56,
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz kayıtlı makale yok',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Makale detayında bookmark simgesine tıklayarak\nmakaleleri çevrimdışı kaydedebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _articles.length,
              itemBuilder: (context, index) {
                final article = _articles[index];
                return Dismissible(
                  key: ValueKey(article.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _remove(article.id),
                  background: Container(
                    color: AppTheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    leading: article.coverImage != null && article.coverImage!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              article.coverImage!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.article, color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.article, color: AppTheme.textSecondary),
                          ),
                    title: Text(
                      article.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${article.author.username} · ${article.formattedDate}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed('/article', arguments: article.id),
                  ),
                );
              },
            ),
    );
  }
}
