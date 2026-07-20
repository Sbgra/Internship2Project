import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/auth_service.dart';

/// Yan menü — yeni özellikler eklendi.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'MyPlatform',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isLoggedIn ? auth.currentUser!.username : 'Misafir',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Ana Sayfa'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.groups),
            title: const Text('Topluluklar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed('/communities');
            },
          ),
          if (auth.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Makale Yaz'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/create-article');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profilim'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .pushNamed('/profile', arguments: auth.currentUser!.id);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Dergilerim'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/magazines');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Çevrimdışı Makaleler'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/offline-articles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Uygulama İkonu'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/settings/icon');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Çıkış', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ] else ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Giriş Yap'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Kayıt Ol'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/register');
              },
            ),
          ],
        ],
      ),
    );
  }
}
