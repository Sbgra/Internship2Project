import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/article_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../widgets/profile_header.dart';

class AuthorProfileScreen extends StatefulWidget {
  final int userId;
  const AuthorProfileScreen({super.key, required this.userId});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
  UserProfileModel? _profile;
  List<ArticleModel> _articles = [];
  bool _loading = true;
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
      final results = await Future.wait([
        ArticleService.getUserProfile(widget.userId),
        ArticleService.getUserArticles(widget.userId),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as UserProfileModel;
          _articles = results[1] as List<ArticleModel>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? 'Profil'),
        actions: [
          if (_profile != null)
            Consumer<AuthService>(
              builder: (context, auth, child) {
                if (auth.isLoggedIn && auth.currentUser!.id == widget.userId) {
                  return IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final updated = await Navigator.of(context).pushNamed('/edit-profile');
                      if (updated == true && mounted) {
                        _load(); // Reload profile
                      }
                    },
                    tooltip: 'Profili Düzenle',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Tekrar Dene')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      if (_profile != null) ProfileHeader(profile: _profile!),
                      if (_articles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Henüz makale yok')),
                        )
                      else
                        ..._articles.map(
                          (a) => ListTile(
                            title: Text(
                              a.title,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              a.formattedDate,
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
                    ],
                  ),
                ),
    );
  }
}
