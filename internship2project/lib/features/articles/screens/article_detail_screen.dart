import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/article_model.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  ArticleDetailModel? _article;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthService>().token;
    try {
      final a = await ArticleService.getArticleById(widget.articleId, token: token);
      if (mounted) setState(() => _article = a);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Makaleyi sil'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sil', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ArticleService.deleteArticle(
        token: context.read<AuthService>().token!,
        articleId: widget.articleId,
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (_loading) {
      return Scaffold(appBar: AppBar(), body: const LoadingIndicator());
    }

    if (_error != null || _article == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Yüklenemedi')),
      );
    }

    final article = _article!;
    final isOwner = auth.isLoggedIn && auth.currentUser!.id == article.authorId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.author.username,
          style: const TextStyle(color: AppTheme.primary, fontSize: 14),
        ),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Sil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Meta
            Text(
              '${article.formattedDate} · ${article.readTime}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // İçerik
            SelectableText(
              article.content,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 32),

            // Yazar kutusu
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed('/profile', arguments: article.authorId),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(
                      article.author.username[0].toUpperCase(),
                      style: const TextStyle(color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    article.author.username,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
