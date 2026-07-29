import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/settings_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// Uygulama ikonu özelleştirme ekranı — sadece üyeler.
class AppIconSettingsScreen extends StatefulWidget {
  const AppIconSettingsScreen({super.key});

  @override
  State<AppIconSettingsScreen> createState() => _AppIconSettingsScreenState();
}

class _AppIconSettingsScreenState extends State<AppIconSettingsScreen> {
  String _selectedIcon = 'default';
  bool _loading = true;
  bool _saving = false;

  static const List<_IconOption> _options = [
    _IconOption('default', 'Varsayılan', Icons.circle, Color(0xFF7C6DFA)),
    _IconOption('dark', 'Koyu', Icons.dark_mode, Color(0xFF2C2C3E)),
    _IconOption('ocean', 'Okyanus', Icons.water, Color(0xFF0D47A1)),
    _IconOption('sunset', 'Gün Batımı', Icons.wb_twilight, Color(0xFFFF6F00)),
    _IconOption('minimal', 'Minimal', Icons.crop_square, Color(0xFF9E9E9E)),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final token = context.read<AuthService>().token!;
      final data = await SettingsService.getMySettings(token);
      if (mounted) {
        setState(() {
          _selectedIcon = data['app_icon'] as String? ?? 'default';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String icon) async {
    setState(() {
      _selectedIcon = icon;
      _saving = true;
    });
    try {
      final token = context.read<AuthService>().token!;
      await SettingsService.updateMySettings(token: token, appIcon: icon);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İkon tercihi kaydedildi')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uygulama İkonu')),
      body: _loading
          ? const LoadingIndicator()
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uygulama simgesini özelleştirin',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Seçtiğiniz ikon ana ekranda görünecektir.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        final opt = _options[index];
                        final isSelected = _selectedIcon == opt.key;
                        return GestureDetector(
                          onTap: _saving ? null : () => _save(opt.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primary
                                    : AppTheme.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: opt.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    opt.icon,
                                    color: opt.color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  opt.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.textPrimary,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                if (isSelected)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primary,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _IconOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _IconOption(this.key, this.label, this.icon, this.color);
}
