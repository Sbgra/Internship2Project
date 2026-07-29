import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/community_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';

/// Topluluk oluşturma ekranı — sadece üyeler.
class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    try {
      final token = context.read<AuthService>().token!;
      
      if (_selectedImage != null) {
        _uploadedImageUrl = await ApiService.uploadImage(
          ApiConstants.mediaUploadImage,
          _selectedImage!,
          token: token,
        );
      }
      
      await CommunityService.createCommunity(
        token: token,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : null,
        image: _uploadedImageUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topluluk oluşturuldu!')),
        );
        Navigator.of(context).pop(true);
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
        title: const Text('Yeni Topluluk'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _submit,
                  child: const Text('Oluştur'),
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
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Topluluk Adı'),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'En az 2 karakter' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Açıklama (opsiyonel)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Kapak Resmi Seç (opsiyonel)'),
              ),
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                Text('Seçilen dosya: ${_selectedImage!.path.split('/').last}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
