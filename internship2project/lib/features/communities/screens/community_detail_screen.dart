import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/community_model.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Topluluk detay ekranı — herkes görebilir, üyeler katılabilir/ayrılabilir.
class CommunityDetailScreen extends StatefulWidget {
  final int communityId;
  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  CommunityDetailModel? _community;
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
      if (mounted) setState(() => _community = data);
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
        await CommunityService.leaveCommunity(
          widget.communityId,
          auth.token!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topluluktan ayrıldınız')),
          );
        }
      } else {
        await CommunityService.joinCommunity(
          widget.communityId,
          auth.token!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Topluluğa katıldınız!')),
          );
        }
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_community?.name ?? 'Topluluk'),
      ),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!))
              : _community == null
                  ? const Center(child: Text('Topluluk bulunamadı'))
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Topluluk başlığı
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:
                                    AppTheme.primary.withOpacity(0.2),
                                child: Text(
                                  _community!.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                  ? const Center(
                                      child: CircularProgressIndicator())
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
                        ],
                      ),
                    ),
    );
  }
}
