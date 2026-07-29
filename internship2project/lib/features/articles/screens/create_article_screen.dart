import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quill_html_editor/quill_html_editor.dart';
import '../../../data/services/article_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class _ChatMessage {
  final String role;
  final String content;
  _ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  State<CreateArticleScreen> createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final QuillEditorController _quillController = QuillEditorController();
  
  bool _isPublic = true;
  bool _loading = false;
  bool _isEditorReady = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  
  // Asistan Dili
  String _selectedLang = 'Türkçe';

  // Çeviri Hedef Dilleri
  final List<String> _targetLanguages = ['İngilizce', 'Almanca', 'Fransızca', 'İspanyolca', 'İtalyanca', 'Rusça', 'Arapça', 'Japonca'];
  final List<String> _selectedTargetLangs = [];

  // Kategoriler
  List<String> _availableCategories = [];
  final List<String> _selectedCategories = [];

  int _currentIndex = 0; // 0 = Editor, 1 = AI Chat
  
  // AI Chat State
  final List<_ChatMessage> _chatMessages = [];
  final _chatInputCtrl = TextEditingController();
  bool _isChatLoading = false;
  final ScrollController _chatScrollCtrl = ScrollController();
  
  // Inline color picker state
  bool _showColorOptions = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ArticleService.getCategories();
      if (mounted) {
        setState(() {
          _availableCategories = cats;
        });
      }
    } catch (e) {
      debugPrint("Kategoriler yüklenemedi: $e");
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _quillController.dispose();
    _chatInputCtrl.dispose();
    _chatScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _generateArticleWithAI() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen konu için başlık girin')));
      return;
    }
    
    setState(() => _loading = true);
    try {
      final token = context.read<AuthService>().token!;
      final res = await ApiService.post(
        '${ApiConstants.baseUrl}/ai/generate-article',
        {'prompt': _titleCtrl.text.trim(), 'language': _selectedLang},
        token: token,
      );
      
      _titleCtrl.text = res['title'] ?? _titleCtrl.text;
      _summaryCtrl.text = res['summary'] ?? '';
      if (_isEditorReady) {
        await _quillController.setText(res['content'] ?? '');
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Makale oluşturuldu!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditorReady) return;

    final token = context.read<AuthService>().token!;
    final content = await _quillController.getText();
    if (content.trim().isEmpty || content == '<p><br></p>') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen içerik girin')),
        );
      }
      return;
    }

    setState(() => _loading = true);
    try {
      if (_selectedImage != null) {
        _uploadedImageUrl = await ApiService.uploadImage(
          ApiConstants.mediaUploadImage,
          _selectedImage!,
          token: token,
        );
      }
      
      await ArticleService.createArticle(
        token: token,
        title: _titleCtrl.text.trim(),
        content: content,
        summary: _summaryCtrl.text.trim().isNotEmpty
            ? _summaryCtrl.text.trim()
            : null,
        coverImage: _uploadedImageUrl,
        isPublic: _isPublic,
        categories: _selectedCategories.isNotEmpty ? _selectedCategories : null,
        targetLanguages: _selectedTargetLangs.isNotEmpty ? _selectedTargetLangs : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedTargetLangs.isNotEmpty 
              ? 'Makale yayınlandı ve çevriliyor!' 
              : 'Makale yayınlandı!'),
          ),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Beklenmeyen hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendChatMessage() async {
    final text = _chatInputCtrl.text.trim();
    if (text.isEmpty) return;
    
    final token = context.read<AuthService>().token;
    if (token == null) return;

    setState(() {
      _chatMessages.add(_ChatMessage(role: 'user', content: text));
      _chatInputCtrl.clear();
      _isChatLoading = true;
    });
    
    _scrollToBottom();

    String currentText = "";
    if (_isEditorReady) {
      currentText = await _quillController.getText();
      currentText = currentText.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
    }

    try {
      final res = await ApiService.post(
        '${ApiConstants.baseUrl}/ai/chat',
        {
          'context': currentText,
          'messages': _chatMessages.map((m) => m.toJson()).toList(),
        },
        token: token,
      );
      
      if (mounted) {
        setState(() {
          _chatMessages.add(_ChatMessage(role: 'model', content: res['reply']));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isChatLoading = false);
      }
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _appendHtmlToEditor(String htmlContent) async {
    if (!_isEditorReady) return;
    final currentHtml = await _quillController.getText();
    await _quillController.setText('$currentHtml <p>$htmlContent</p>');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Editöre eklendi!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Makale Yaz'),
        actions: [
          _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      elevation: 0,
                    ),
                    child: const Text('Yayınla', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: 'Editör'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Asistan'),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildEditorTab(),
          _buildAiChatTab(),
        ],
      ),
    );
  }

  Widget _buildEditorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Başlık',
                      hintStyle: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                    ),
                    maxLines: null,
                    validator: (v) => (v == null || v.isEmpty) ? 'Başlık gerekli' : null,
                  ),
                ),
                IconButton(
                  onPressed: _generateArticleWithAI,
                  icon: const Icon(Icons.auto_fix_high, color: AppTheme.primary),
                  tooltip: 'Yapay Zeka ile Oluştur',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Editör Alanı (Çerçevesiz, temiz beyaz)
            SizedBox(
              height: 500,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppTheme.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Araç Çubuğu
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppTheme.divider)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ToolBar(
                              toolBarColor: Colors.transparent,
                              padding: const EdgeInsets.all(4),
                              iconSize: 22,
                              controller: _quillController,
                              toolBarConfig: const [
                                ToolBarStyle.bold,
                                ToolBarStyle.italic,
                                ToolBarStyle.underline,
                                ToolBarStyle.strike,
                                ToolBarStyle.background,
                                ToolBarStyle.size,
                                ToolBarStyle.align,
                                ToolBarStyle.listBullet,
                                ToolBarStyle.listOrdered,
                              ],
                              customButtons: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _showColorOptions = !_showColorOptions;
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.color_lens, size: 22, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Satır içi (inline) Renk Paleti
                        if (_showColorOptions)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: const BoxDecoration(
                              color: AppTheme.surface,
                              border: Border(bottom: BorderSide(color: AppTheme.divider, width: 1)),
                            ),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                Colors.white, Colors.black, Colors.grey, Colors.red, Colors.pink, 
                                Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue, 
                                Colors.cyan, Colors.teal, Colors.green, Colors.yellow, Colors.orange
                              ].map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    final hex = '#${color.value.toRadixString(16).substring(2, 8)}';
                                    _quillController.setFormat(format: 'color', value: hex);
                                    setState(() => _showColorOptions = false);
                                  },
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.divider, width: 1.5),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // İçerik Alanı
                        Expanded(
                          child: QuillHtmlEditor(
                            text: "Hikayenizi anlatın...",
                            controller: _quillController,
                            isEnabled: true,
                            minHeight: 300,
                            textStyle: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              height: 1.6,
                            ),
                            hintTextStyle: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                            hintTextPadding: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            backgroundColor: AppTheme.background,
                            onEditorCreated: () {
                              setState(() {
                                _isEditorReady = true;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditorReady)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
                  
                  // Ek Ayarlar (Medium tarzı ince çizgili)
                  const Divider(color: AppTheme.divider),
                  const SizedBox(height: 16),
                  const Text('Gelişmiş Ayarlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const Text('Yazı Dili:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _selectedLang,
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        underline: const SizedBox(),
                        items: ['Türkçe', 'İngilizce', 'Almanca', 'Fransızca', 'İspanyolca'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedLang = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _summaryCtrl,
                    decoration: const InputDecoration(labelText: 'Özet (opsiyonel)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Kategoriler
                  if (_availableCategories.isNotEmpty) ...[
                    const Text('Kategoriler', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableCategories.map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: Colors.black12,
                          checkmarkColor: AppTheme.textPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          backgroundColor: AppTheme.divider,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Otomatik Çeviri Dilleri
                  const Text('Otomatik Çeviri Dilleri', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const Text('Seçtiğiniz dillere yayınlandığında otomatik çevrilir.', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _targetLanguages.map((lang) {
                      final isSelected = _selectedTargetLangs.contains(lang);
                      return FilterChip(
                        label: Text(lang),
                        selected: isSelected,
                        selectedColor: Colors.black12,
                        checkmarkColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        side: BorderSide.none,
                        backgroundColor: AppTheme.divider,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTargetLangs.add(lang);
                            } else {
                              _selectedTargetLangs.remove(lang);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Görsel Seçme
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Kapak Fotoğrafı Ekle (opsiyonel)'),
                  ),
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 8),
                    Text('Seçilen dosya: ${_selectedImage!.path.split('/').last}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Herkese açık', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
                    value: _isPublic,
                    onChanged: (v) => setState(() => _isPublic = v),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildAiChatTab() {
    return Column(
      children: [
        Expanded(
          child: _chatMessages.isEmpty
              ? const Center(
                  child: Text('AI Asistan ile sohbet et.\nÖrn: "Bana bir giriş paragrafı yaz."', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
                )
              : ListView.builder(
                  controller: _chatScrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chatMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _chatMessages[index];
                    final isUser = msg.role == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primary : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: isUser ? null : Border.all(color: AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.content,
                              style: TextStyle(color: isUser ? Colors.white : AppTheme.textPrimary),
                            ),
                            if (!isUser) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _appendHtmlToEditor(msg.content),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Yazıya Ekle', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_isChatLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: const Border(top: BorderSide(color: AppTheme.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatInputCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Bir şeyler yaz...',
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onSubmitted: (_) => _sendChatMessage(),
                ),
              ),
              IconButton(
                onPressed: _isChatLoading ? null : _sendChatMessage,
                icon: const Icon(Icons.send, color: AppTheme.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

