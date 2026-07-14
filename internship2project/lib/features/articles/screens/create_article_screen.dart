import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _isPublic = true;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ArticleService.createArticle(
        token: context.read<AuthService>().token!,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        summary: _summaryCtrl.text.trim().isNotEmpty
            ? _summaryCtrl.text.trim()
            : null,
        isPublic: _isPublic,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Makale yayınlandı!')));
        Navigator.of(context).pop();
      }
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
      appBar: AppBar(
        title: const Text('Yeni Makale'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _submit,
                  child: const Text('Yayınla'),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Başlık'),
                maxLines: null,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryCtrl,
                decoration: const InputDecoration(labelText: 'Özet (opsiyonel)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'İçerik'),
                maxLines: null,
                minLines: 10,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'İçerik gerekli' : null,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Herkese açık'),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
