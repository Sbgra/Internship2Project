import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../widgets/auth_form_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().register(
            _usernameCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
      if (mounted) Navigator.of(context).pushReplacementNamed('/');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              AuthFormField(
                label: 'Kullanıcı Adı',
                controller: _usernameCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Kullanıcı adı gerekli';
                  if (v.length < 3) return 'En az 3 karakter olmalı';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthFormField(
                label: 'E-posta',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'E-posta gerekli';
                  if (!v.contains('@')) return 'Geçerli e-posta girin';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AuthFormField(
                label: 'Şifre',
                controller: _passwordCtrl,
                isPassword: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Şifre gerekli';
                  if (v.length < 6) return 'En az 6 karakter olmalı';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kayıt Ol'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Zaten hesabınız var mı? Giriş Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
