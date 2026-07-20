import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Topluluk listesi ekranı — herkes görebilir, üyeler oluşturabilir.
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  List<CommunityListItemModel> _communities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CommunityService.listCommunities();
      if (mounted) setState(() => _communities = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Topluluklar')),
      floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context)
                    .pushNamed('/create-community');
                if (result == true) _load();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: _loading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _load,
              child: _communities.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_outlined,
                              size: 56,
                              color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz topluluk yok',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _communities.length,
                      itemBuilder: (context, index) {
                        final c = _communities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            child: Text(
                              c.name[0].toUpperCase(),
                              style: const TextStyle(color: AppTheme.primary),
                            ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${c.memberCount} üye${c.description != null ? ' · ${c.description}' : ''}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          onTap: () async {
                            await Navigator.of(context).pushNamed(
                              '/community',
                              arguments: c.id,
                            );
                            _load();
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
