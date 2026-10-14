import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/users/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _users = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Kullanıcıları çekerken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isLoggedIn = auth.isLoggedIn;
    final currentUser = auth.currentUser?.username;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Kişiler', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 1,
      ),
      body: !isLoggedIn
          ? Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.orange.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Kişileri görmek ve sohbete katılmak için lütfen giriş yapın.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('Henüz başka kullanıcı yok.'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final username = user['username'] ?? 'Bilinmeyen';
                        final profilePic = user['profile_picture'];
                        
                        // Kendimizi listede göstermeyelim
                        if (username == currentUser) return const SizedBox.shrink();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primary,
                            backgroundImage: profilePic != null && profilePic.isNotEmpty
                                ? NetworkImage(profilePic.startsWith('http') 
                                    ? profilePic 
                                    : '${ApiConstants.baseUrl}/$profilePic')
                                : null,
                            child: profilePic == null || profilePic.isEmpty
                                ? Text(
                                    username[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          title: Text(
                            username,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: const Text('Sohbet etmek için dokun'),
                          onTap: () {
                            // Seçilen kullanıcıyla sohbet ekranını aç
                            Navigator.pushNamed(
                              context,
                              '/chat-detail',
                              arguments: {
                                'receiverId': username,
                                'receiverName': username,
                                'receiverAvatar': profilePic != null && profilePic.isNotEmpty
                                    ? (profilePic.startsWith('http') ? profilePic : '${ApiConstants.baseUrl}/$profilePic')
                                    : null,
                              },
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
