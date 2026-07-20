import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/magazine_model.dart';
import '../../../data/services/magazine_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Dergi listesi ekranı — sadece üyeler kendi dergilerini görebilir.
class MagazinesScreen extends StatefulWidget {
  const MagazinesScreen({super.key});

  @override
  State<MagazinesScreen> createState() => _MagazinesScreenState();
}

class _MagazinesScreenState extends State<MagazinesScreen> {
  List<MagazineModel> _magazines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token!;
      final data = await MagazineService.getMyMagazines(token);
      if (mounted) setState(() => _magazines = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dergilerim')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.of(context).pushNamed('/create-magazine');
          if (result == true) _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _load,
              child: _magazines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined,
                              size: 56,
                              color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'Henüz dergi oluşturmadınız',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Makalelerinizi bir dergi altında\ntoplayabilirsiniz.',
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
                      itemCount: _magazines.length,
                      itemBuilder: (context, index) {
                        final m = _magazines[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            child: const Icon(Icons.menu_book,
                                color: AppTheme.primary, size: 20),
                          ),
                          title: Text(
                            m.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${m.articleCount} makale${m.description != null ? ' · ${m.description}' : ''}',
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
                              '/magazine',
                              arguments: m.id,
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
