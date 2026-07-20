import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/article_model.dart';
import '../../../data/models/stats_model.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/stats_service.dart';
import '../../../data/services/offline_service.dart';
import '../../../data/services/magazine_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/stats_widget.dart';
import '../widgets/clap_button.dart';
import '../widgets/tts_player_widget.dart';

class ArticleDetailScreen extends StatefulWidget {
  final int articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  ArticleDetailModel? _article;
  ArticleStatsModel? _stats;
  ClapResultModel? _clapResult;
  bool _loading = true;
  bool _clapLoading = false;
  bool _isSaved = false;
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

      // İstatistikleri yükle (herkes görebilir)
      _loadStats();

      // Alkış bilgisi yükle
      _loadClaps();

      // Görüntülenme kaydet (başarısız olursa sessiz geç)
      try {
        StatsService.recordView(widget.articleId);
      } catch (_) {
        // Görüntülenme kaydı başarısız olabilir, kullanıcıyı etkilemez
      }

      // Çevrimdışı kayıt durumunu kontrol et
      if (token != null) {
        final saved = await OfflineService.isArticleSaved(widget.articleId);
        if (mounted) setState(() => _isSaved = saved);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await StatsService.getArticleStats(widget.articleId);
      if (mounted) setState(() => _stats = stats);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İstatistikler yüklenemedi: ${e.message}')),
        );
      }
    } catch (_) {
      // Kritik değil, sessiz geç
    }
  }

  Future<void> _loadClaps() async {
    try {
      final token = context.read<AuthService>().token;
      final claps = await StatsService.getClaps(widget.articleId, token: token);
      if (mounted) setState(() => _clapResult = claps);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alkış bilgisi yüklenemedi: ${e.message}')),
        );
      }
    } catch (_) {
      // Kritik değil, sessiz geç
    }
  }

  Future<void> _onClap(int count) async {
    setState(() => _clapLoading = true);
    try {
      final token = context.read<AuthService>().token;
      final result = await StatsService.clap(
        widget.articleId,
        count,
        token: token,
      );
      if (mounted) {
        setState(() {
          _clapResult = result;
          // Stats'ı da güncelle
          if (_stats != null) {
            _stats = ArticleStatsModel(
              articleId: _stats!.articleId,
              viewCount: _stats!.viewCount,
              clapCount: result.totalClaps,
            );
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alkış gönderilemedi: ${e.message}')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alkış gönderilirken bir hata oluştu')),
        );
      }
    } finally {
      if (mounted) setState(() => _clapLoading = false);
    }
  }

  Future<void> _toggleOffline() async {
    if (_article == null) return;
    if (_isSaved) {
      await OfflineService.removeArticle(widget.articleId);
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çevrimdışı listesinden kaldırıldı')),
        );
      }
    } else {
      await OfflineService.saveArticle(_article!);
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çevrimdışı okumak için kaydedildi')),
        );
      }
    }
  }

  Future<void> _addToMagazine() async {
    if (!mounted) return;
    final token = context.read<AuthService>().token;
    if (token == null) return;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<dynamic>>(
          future: MagazineService.getMyMagazines(token),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('Eklenecek dergi bulunamadı. Önce bir dergi oluşturun.')),
              );
            }

            final magazines = snapshot.data!;
            return ListView.builder(
              itemCount: magazines.length,
              itemBuilder: (context, index) {
                final mag = magazines[index];
                return ListTile(
                  title: Text(mag.title),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await MagazineService.addArticle(
                        token: token,
                        magazineId: mag.id,
                        articleId: widget.articleId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${mag.title} dergisine eklendi')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dergiye eklenirken hata oluştu (belki zaten eklidir)')),
                        );
                      }
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
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
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.author.username,
          style: const TextStyle(color: AppTheme.primary, fontSize: 14),
        ),
        actions: [
          // Dergiye ekle — sadece üyeler
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.library_add),
              onPressed: _addToMagazine,
              tooltip: 'Dergiye Ekle',
            ),
          // Çevrimdışı kaydet — sadece üyeler
          if (isLoggedIn)
            IconButton(
              icon: Icon(
                _isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: _isSaved ? AppTheme.primary : AppTheme.textPrimary,
              ),
              onPressed: _toggleOffline,
              tooltip: _isSaved ? 'Kaydedildi' : 'Çevrimdışı Kaydet',
            ),
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
            const SizedBox(height: 12),

            // İstatistikler — herkes görebilir
            if (_stats != null) ...[
              StatsWidget(stats: _stats!),
              const SizedBox(height: 16),
            ],

            // Sesli dinleme — sadece üyeler
            if (isLoggedIn) ...[
              TtsPlayerWidget(text: article.content),
              const SizedBox(height: 16),
            ],

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

            // Alkış butonu — herkes kullanabilir
            if (_clapResult != null)
              Center(
                child: ClapButton(
                  totalClaps: _clapResult!.totalClaps,
                  remainingClaps: _clapResult!.remainingClaps,
                  isLoading: _clapLoading,
                  onClap: _onClap,
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
