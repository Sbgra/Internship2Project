import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'topic_detail_screen.dart'; // We will create this next

class CommunityDetailScreen extends StatefulWidget {
  final int communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  CommunityDetailModel? _community;
  List<dynamic> _topics = [];
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

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
      final token = context.read<AuthService>().token;
      final data = await CommunityService.getCommunityDetail(
        widget.communityId,
        token: token,
      );
      final topics = await CommunityService.getForumTopics(widget.communityId);
      if (mounted) {
        setState(() {
          _community = data;
          _topics = topics;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleMembership() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn || _community == null) return;

    setState(() => _actionLoading = true);
    try {
      if (_community!.isMember) {
        await CommunityService.leaveCommunity(widget.communityId, auth.token!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topluluktan ayrıldınız')),
          );
        }
      } else {
        await CommunityService.joinCommunity(widget.communityId, auth.token!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topluluğa katıldınız!')),
          );
        }
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _showCreateTopicDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Yeni Konu Aç', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Başlık'),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'İçerik'),
              maxLines: 4,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) return;
              try {
                final token = context.read<AuthService>().token!;
                await CommunityService.createForumTopic(
                  widget.communityId,
                  token,
                  titleCtrl.text.trim(),
                  contentCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              } catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Hata: $e')));
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(_community?.name ?? 'Topluluk')),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
          : _community == null
          ? const Center(child: Text('Topluluk bulunamadı', style: TextStyle(color: AppTheme.textSecondary)))
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topluluk başlığı
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                          backgroundImage: _community!.image != null && _community!.image!.isNotEmpty
                              ? NetworkImage(_community!.image!)
                              : null,
                          child: _community!.image == null || _community!.image!.isEmpty
                              ? Text(
                                  _community!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _community!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_community!.memberCount} üye',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (_community!.description != null &&
                        _community!.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        _community!.description!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Katıl/Ayrıl butonu — sadece üyeler
                    if (auth.isLoggedIn)
                      SizedBox(
                        width: double.infinity,
                        child: _actionLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _community!.isMember
                            ? OutlinedButton.icon(
                                onPressed: _toggleMembership,
                                icon: const Icon(Icons.logout),
                                label: const Text('Ayrıl'),
                              )
                            : ElevatedButton.icon(
                                onPressed: _toggleMembership,
                                icon: const Icon(Icons.group_add),
                                label: const Text('Katıl'),
                              ),
                      ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tartışmalar (Forum)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        if (auth.isLoggedIn && _community!.isMember)
                          TextButton.icon(
                            onPressed: _showCreateTopicDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Konu'),
                          )
                      ],
                    ),
                    const Divider(color: AppTheme.divider),
                    if (_topics.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('Henüz konu açılmamış.', style: TextStyle(color: AppTheme.textSecondary)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _topics.length,
                        separatorBuilder: (_, __) => const Divider(color: AppTheme.divider),
                        itemBuilder: (context, index) {
                          final topic = _topics[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(topic['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            subtitle: Text('Yazar: ${topic['author']?['username'] ?? 'Bilinmiyor'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TopicDetailScreen(topicId: topic['id'], communityId: widget.communityId),
                                ),
                              ).then((_) => _load());
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
