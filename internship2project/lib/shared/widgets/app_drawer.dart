import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';

/// Yan menü — Medium tarzı, saf minimalist, beyaz ve siyah.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final username = auth.isLoggedIn ? auth.currentUser!.username : 'Misafir';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'M';

    return Drawer(
      backgroundColor: AppTheme.background,
      elevation: 0,
      child: Column(
        children: [
          // Temiz Minimalist Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.divider,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MyPlatform',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.isLoggedIn ? '@$username' : 'Giriş Yapılmadı',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_outlined,
                  title: 'Ana Sayfa',
                  onTap: () => Navigator.of(context).pushReplacementNamed('/'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.people_outline,
                  title: 'Topluluklar',
                  onTap: () => Navigator.of(context).pushNamed('/communities'),
                ),
                
                if (auth.isLoggedIn) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Divider(color: AppTheme.divider),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.edit_outlined,
                    title: 'Makale Yaz',
                    onTap: () => Navigator.of(context).pushNamed('/create-article'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline,
                    title: 'Profilim',
                    onTap: () => Navigator.of(context).pushNamed('/profile', arguments: auth.currentUser!.id),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: 'Dergilerim',
                    onTap: () => Navigator.of(context).pushNamed('/magazines'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.bookmark_outline,
                    title: 'Çevrimdışı Makaleler',
                    onTap: () => Navigator.of(context).pushNamed('/offline-articles'),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Divider(color: AppTheme.divider),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.palette_outlined,
                    title: 'Uygulama İkonu',
                    onTap: () => Navigator.of(context).pushNamed('/settings/icon'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout_outlined,
                    title: 'Çıkış Yap',
                    isDestructive: true,
                    onTap: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Divider(color: AppTheme.divider),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.login_outlined,
                    title: 'Giriş Yap',
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_add_outlined,
                    title: 'Kayıt Ol',
                    onTap: () => Navigator.of(context).pushNamed('/register'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppTheme.error : AppTheme.textPrimary;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15, // Medium'da menü linkleri biraz daha ince ve küçüktür
          fontWeight: FontWeight.w400,
          color: color,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

