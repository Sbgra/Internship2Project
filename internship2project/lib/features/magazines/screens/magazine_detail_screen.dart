import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/magazine_model.dart';
import '../../../data/services/magazine_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

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
                        ],
                      ),
                    ),
    );
  }
}
