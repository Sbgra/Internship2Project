import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import 'package:file_picker/file_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _bioController = TextEditingController();
  final _photoController = TextEditingController();
  bool _isLoading = false;
  File? _selectedImage;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    if (auth.currentUser != null) {
      _bioController.text = auth.currentUser!.bio ?? '';
      _photoController.text = auth.currentUser!.profilePicture ?? '';
    }
  }

  Future<void> _pickImage() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          setState(() => _selectedImage = File(result.files.single.path!));
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          setState(() => _selectedImage = File(picked.path));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    try {
      if (_selectedImage != null) {
        _uploadedImageUrl = await ApiService.uploadImage(
          ApiConstants.mediaUploadImage,
          _selectedImage!,
          token: auth.token,
        );
      } else {
        _uploadedImageUrl = _photoController.text.trim();
      }

      await auth.updateBio(_bioController.text.trim());
      await auth.updateProfileCustomization(_uploadedImageUrl!.isEmpty ? null : _uploadedImageUrl);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil güncellenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_selectedImage != null) ...[
              const SizedBox(height: 8),
              Text('Seçilen dosya: ${_selectedImage!.path.split('/').last}'),
            ] else if (_photoController.text.isNotEmpty) ...[
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(_photoController.text),
              ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text('Profil Fotoğrafı Seç'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Biyografi',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
