import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/magazine_model.dart';
import '../../../data/services/magazine_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../communities/widgets/comment_tree_widget.dart';

/// Dergi detay ekranı — içindeki makaleleri listeler.
class MagazineDetailScreen extends StatefulWidget {
  final int magazineId;
  const MagazineDetailScreen({super.key, required this.magazineId});

  @override
  State<MagazineDetailScreen> createState() => _MagazineDetailScreenState();
}

class _MagazineDetailScreenState extends State<MagazineDetailScreen> {
  MagazineDetailModel? _magazine;
  bool _loading = true;
  String? _error;
  List<CommentModel> _comments = [];
  bool _commentsLoading = false;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MagazineService.getMagazineDetail(widget.magazineId);
      if (mounted) setState(() => _magazine = data);
      _loadComments();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    try {
      final res = await ApiService.getList('${ApiConstants.baseUrl}/comments/magazines/${widget.magazineId}');
      if (mounted) {
        setState(() {
          _comments = res.map((c) => CommentModel(
            id: c['id'],
            authorName: c['username'] ?? 'Kullanıcı',
            profilePicture: c['profile_picture'],
            content: c['content'] ?? '',
            createdAt: c['created_at'] ?? '',
            replies: [],
          )).toList();
        });
      }
    } catch (_) {
      // sessiz geç
    } finally {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _submitComment(int? parentId) async {
    final token = context.read<AuthService>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız')));
      return;
    }
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    
    try {
      await ApiService.post(
        '${ApiConstants.baseUrl}/comments/magazines/${widget.magazineId}',
        {'content': text},
        token: token,
      );
      _commentCtrl.clear();
      _loadComments();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yorum eklenemedi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_magazine?.title ?? 'Dergi'),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!))
              : _magazine == null
                  ? const Center(child: Text('Dergi bulunamadı'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        children: [
                          // Dergi bilgisi
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _magazine!.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (_magazine!.description != null &&
                                    _magazine!.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _magazine!.description!,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${_magazine!.articleCount} makale',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                              ],
                            ),
                          ),

                          // Makale listesi
                          if (_magazine!.articles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  'Bu dergide henüz makale yok',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            )
                          else
                            ..._magazine!.articles.map(
                              (a) => ListTile(
                                title: Text(
                                  a.title,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  '${a.author.username} · ${a.formattedDate}',
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
                                onTap: () => Navigator.of(context)
                                    .pushNamed('/article', arguments: a.id),
                              ),
                            ),
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Text('Yorumlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: context.watch<AuthService>().isLoggedIn
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentCtrl,
                                          decoration: InputDecoration(
                                            hintText: 'Yorumunuzu yazın...',
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          ),
                                          maxLines: null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _submitComment(null),
                                        icon: const Icon(Icons.send, color: AppTheme.primary),
                                      ),
                                    ],
                                  )
                                : const Text('Yorum yapmak için giriş yapmalısınız.', style: TextStyle(color: AppTheme.textSecondary)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: _commentsLoading
                                ? const Center(child: CircularProgressIndicator())
                                : CommentTreeWidget(
                                    comments: _comments,
                                    onReply: (parentId) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yanıtlamak için yukarıdaki alanı kullanabilirsiniz')));
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
