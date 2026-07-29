import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/community_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/comment_tree_widget.dart';

class TopicDetailScreen extends StatefulWidget {
  final int topicId;
  final int communityId;
  
  const TopicDetailScreen({
    super.key,
    required this.topicId,
    required this.communityId,
  });

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _topicDetails;
  final _commentCtrl = TextEditingController();
  int? _replyingToId;

  @override
  void initState() {
    super.initState();
    _load();
  }
  
  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final details = await CommunityService.getTopicDetails(widget.topicId);
      if (mounted) setState(() => _topicDetails = details);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  List<CommentModel> _buildCommentTree(List<dynamic> posts) {
    final Map<int, CommentModel> commentMap = {};
    final List<CommentModel> roots = [];

    for (var p in posts) {
      commentMap[p['id']] = CommentModel(
        id: p['id'],
        authorName: p['author']?['username'] ?? 'Bilinmiyor',
        profilePicture: p['author']?['profile_picture'],
        content: p['content'] ?? '',
        createdAt: p['created_at'] ?? '',
        parentId: p['parent_id'],
        replies: [],
      );
    }

    for (var p in posts) {
      final comment = commentMap[p['id']]!;
      if (comment.parentId != null && commentMap.containsKey(comment.parentId)) {
        commentMap[comment.parentId]!.replies.add(comment);
      } else {
        roots.add(comment);
      }
    }

    return roots;
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final token = context.read<AuthService>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için giriş yapmalısınız')),
      );
      return;
    }

    try {
      await CommunityService.createTopicPost(
        widget.topicId,
        token,
        text,
        parentId: _replyingToId,
      );
      _commentCtrl.clear();
      setState(() => _replyingToId = null);
      FocusScope.of(context).unfocus();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isLoggedIn = auth.isLoggedIn;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tartışma'),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
          : _topicDetails == null
          ? const Center(child: Text('Konu bulunamadı'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Konu Başlığı ve İçeriği
                        Container(
                          color: AppTheme.surface,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _topicDetails!['title'] ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _topicDetails!['content'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.divider),
                        
                        // Yorum Ağacı
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
                          child: CommentTreeWidget(
                            comments: _buildCommentTree(_topicDetails!['posts'] ?? []),
                            onReply: (parentId) {
                              if (!isLoggedIn) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Yanıtlamak için giriş yapın')),
                                );
                                return;
                              }
                              setState(() => _replyingToId = parentId);
                              FocusScope.of(context).requestFocus();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoggedIn)
                  Container(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 12,
                      left: 16,
                      right: 16,
                      top: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_replyingToId != null)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Yanıtlama modu aktif (ID: $_replyingToId)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: AppTheme.textSecondary),
                                onPressed: () => setState(() => _replyingToId = null),
                              )
                            ],
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  hintText: _replyingToId != null ? 'Yanıtınızı yazın...' : 'Yorum yap...',
                                  filled: true,
                                  fillColor: AppTheme.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _submitComment(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                                onPressed: _submitComment,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
