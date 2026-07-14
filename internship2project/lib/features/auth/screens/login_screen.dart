import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../widgets/auth_form_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthService>().login(
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
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
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
                    : const Text('Giriş Yap'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/register'),
                child: const Text('Hesabınız yok mu? Kayıt Ol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
