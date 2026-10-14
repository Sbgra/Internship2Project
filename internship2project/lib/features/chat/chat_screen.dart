import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cryptography/cryptography.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../data/services/auth_service.dart';
import '../../../data/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/chat_encryption_service.dart';
import 'widgets/chat_media_widgets.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocketChannel? _channel;
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  SecretKey? _encryptionKey;
  
  // Pagination (Sayfalama) Değişkenleri
  int _offset = 0;
  final int _limit = 20; // 10 mesaj ekranı doldurmadığı için scroll tetiklenmiyordu, 20'ye çıkardık
  bool _hasMore = true;
  bool _isFetchingMore = false;
  
  // Yazıyor... (Typing) durumu
  bool _isOtherTyping = false;
  Timer? _typingTimer;
  bool _amITyping = false;
  // İnternet bağlantısı durumu
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isConnected = true;
  bool _isIntentionalClose = false; // Sonsuz döngüyü önlemek için
  bool _isUploadingMedia = false; // Medya/ses yüklenirken loading durumu

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // İnternet durumunu dinle (Hata olursa ekranı çökertmemesi için try-catch)
    try {
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
        debugPrint("İnternet Durumu Değişti: $result");
        final bool isOnline = result.isNotEmpty && !result.contains(ConnectivityResult.none);
        if (!_isConnected && isOnline) {
          debugPrint("İnternet Geri Geldi! Yeniden bağlanılıyor...");
          _reconnectAndReload();
        }
        if (mounted && _isConnected != isOnline) {
          setState(() {
            _isConnected = isOnline;
          });
        }
      });
    } catch (e) {
      debugPrint("Connectivity plugini başlatılamadı: $e");
    }

    // Ekran açıldığında verileri çekmeye başla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  Future<void> _reconnectAndReload() async {
    // 1. Eski WebSocket'i kapat (Kendi kapattığımız için onDone tetiklenince döngüye girmesin diye flag ayarlıyoruz)
    _isIntentionalClose = true;
    _channel?.sink.close();
    
    // 2. Sayfalama verilerini sıfırla ama EKRANDAKİ MESAJLARI SİLME!
    setState(() {
      _offset = 0;
      _hasMore = true;
    });
    
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) return;
    
    final myUserId = auth.currentUser!.username;
    
    // 3. Yeniden API'ye bağlanıp geçmişi almayı dene
    await _fetchHistory(myUserId);
    
    // Eğer fetchHistory başarılıysa (hata fırlatmadıysa ve 200 döndüyse) _isConnected'i true yaparız.
    // _connectWebSocket zaten _fetchHistory'nin hemen ardından çağrılacak.
    _connectWebSocket(myUserId);
  }

  Future<void> _initChat() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    final myUserId = auth.currentUser!.username;

    // 0. Önce internetsiz kalsak bile mesajların görünmesi için yerel önbelleği yükle
    await _loadCachedHistory(myUserId);

    // 1. FastAPI'den sohbet şifreleme anahtarını (ChaCha20-Poly1305) al
    await _fetchEncryptionKey(myUserId);

    // 2. Backend'den Güncel Geçmiş Mesajları Çek (Varsa yenileri ekler ve çözer)
    await _fetchHistory(myUserId);

    // 3. WebSocket Bağlantısını Kur
    _connectWebSocket(myUserId);
  }

  Future<void> _fetchEncryptionKey(String myUserId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/chat/key/$myUserId/${widget.receiverId}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final base64Key = data['key'];
        if (base64Key != null) {
          _encryptionKey = ChatEncryptionService.createSecretKeyFromBase64(base64Key);
          debugPrint("ChaCha20-Poly1305 şifreleme anahtarı başarıyla yüklendi.");
        }
      }
    } catch (e) {
      debugPrint("Şifreleme anahtarı alınırken hata: $e");
    }
  }

  // --- ÖNBELLEK (CACHE) SİSTEMİ ---
  Future<void> _loadCachedHistory(String myUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'chat_cache_${myUserId}_${widget.receiverId}';
      final String? cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> decoded = jsonDecode(cachedData);
        final List<Map<String, dynamic>> cachedList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(cachedList);
            _isLoading = false; // Önbellekten veri geldiyse yükleniyor animasyonunu kapat
          });
        }
      }
    } catch (e) {
      debugPrint("Önbellek okuma hatası: $e");
    }
  }

  Future<void> _saveCacheHistory(String myUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'chat_cache_${myUserId}_${widget.receiverId}';
      // Son 50 mesajı telefona kaydet ki internetsiz girince boş kalmasın
      final toSave = _messages.take(50).toList();
      await prefs.setString(cacheKey, jsonEncode(toSave));
    } catch (e) {
      debugPrint("Önbellek kaydetme hatası: $e");
    }
  }
  // -------------------------------

  void _onScroll() {
    // Listeyi reverse: true yaptığımız için, eski mesajlara gitmek demek aşağı doğru (maxScrollExtent) kaydırmak demektir
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 &&
        !_isFetchingMore &&
        _hasMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) return;
    
    setState(() => _isFetchingMore = true);
    
    await _fetchHistory(auth.currentUser!.username, isLoadMore: true);
    
    setState(() => _isFetchingMore = false);
    // reverse: true olduğu için jumpTo yapmamıza gerek yok! Flutter bunu otomatik halleder.
  }

  Future<void> _fetchHistory(String myUserId, {bool isLoadMore = false}) async {
    try {
      // Eğer anahtar henüz alınamadıysa tekrar dene
      if (_encryptionKey == null) {
        await _fetchEncryptionKey(myUserId);
      }

      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/api/chat/history/$myUserId/${widget.receiverId}?limit=$_limit&offset=$_offset'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data.length < _limit) {
          _hasMore = false; // 10'dan az geldiyse demek ki başka eski mesaj kalmamış
        }

        final List<Map<String, dynamic>> newMessages = [];
        // Python kronolojik yolluyor, biz reverse: true kullandığımız için en yenisi 0'da olmalı
        for (var item in data.reversed) {
          final rawContent = item['content'] ?? '';
          String decryptedText = rawContent;
          if (_encryptionKey != null) {
            decryptedText = await ChatEncryptionService.decrypt(
              cipherTextFormatted: rawContent,
              secretKey: _encryptionKey!,
            );
          }

          newMessages.add({
            'sender': item['sender_id'],
            'text': decryptedText,
            'time': _formatTime(item['created_at']),
          });
        }

        setState(() {
          if (isLoadMore) {
            // Eski mesajları listenin SONUNA ekliyoruz
            _messages.addAll(newMessages);
          } else {
            // İlk açılışta olanları temizle, yeni gelenleri koy
            _messages.clear();
            _messages.addAll(newMessages);
          }
          _offset += data.length;
          _isLoading = false;
          _isConnected = true; // İnternetin geri geldiğini ve verileri başarıyla çektiğimizi doğruladık
        });
        
        // Yeni mesajlar geldikten sonra önbelleği (telefon hafızasını) güncelle
        _saveCacheHistory(myUserId);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && 
              _scrollController.position.maxScrollExtent <= 0 && 
              _hasMore && 
              !_isFetchingMore) {
            _loadMoreMessages();
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _isConnected = false;
        });
      }
    } catch (e) {
      debugPrint('Geçmiş mesajları çekerken hata: $e');
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
    }
  }

  void _connectWebSocket(String myUserId) {
    String wsUrl = 'ws://localhost:8000/ws/chat/$myUserId';
    if (!kIsWeb && Platform.isAndroid) {
      wsUrl = 'ws://10.0.2.2:8000/ws/chat/$myUserId';
    }

    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    
    _channel!.stream.listen(
      (message) async {
        if (mounted) {
          try {
            final data = jsonDecode(message.toString());
            if (data['error'] != null) return;
            
            if (data['type'] == 'typing') {
              setState(() {
                _isOtherTyping = data['is_typing'] ?? false;
              });
              return;
            }

            final incomingText = data['message'] ?? '';
            String decryptedText = incomingText;
            if (_encryptionKey != null) {
              decryptedText = await ChatEncryptionService.decrypt(
                cipherTextFormatted: incomingText,
                secretKey: _encryptionKey!,
              );
            }
            
            setState(() {
              // Yeni gelen mesajı index 0'a ekle
              _messages.insert(0, {
                'sender': data['sender_id'],
                'text': decryptedText,
                'time': _formatTime(data['created_at']),
              });
              _scrollToBottom();
            });
            
            // Yeni mesaj geldiğinde telefondaki yedeği de güncelle
            _saveCacheHistory(myUserId);
          } catch (e) {
            debugPrint('Mesaj parse hatası: $e');
          }
        }
      },
      onDone: () {
        debugPrint("WebSocket Bağlantısı Koptu (onDone)!");
        if (mounted && !_isIntentionalClose) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              debugPrint("Soket koptuğu için otomatik yeniden bağlanılıyor...");
              _reconnectAndReload();
            }
          });
        }
        _isIntentionalClose = false;
      },
      onError: (error) {
        debugPrint("WebSocket Hatası (onError): $error");
        if (mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              debugPrint("Soket hatası yüzünden otomatik yeniden bağlanılıyor...");
              _reconnectAndReload();
            }
          });
        }
      }
    );
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final DateTime dt = DateTime.parse(isoString).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendTypingStatus(bool isTyping) {
    if (_channel != null && _amITyping != isTyping) {
      _amITyping = isTyping;
      final payload = {
        'type': 'typing',
        'receiver_id': widget.receiverId,
        'is_typing': isTyping,
      };
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty) {
      _sendTypingStatus(true);
      
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _sendTypingStatus(false);
      });
    } else {
      _typingTimer?.cancel();
      _sendTypingStatus(false);
    }
  }

  Future<void> _sendMessage(String username) async {
    if (_controller.text.trim().isNotEmpty && _channel != null) {
      final messageText = _controller.text.trim();

      // Anahtarı kontrol et, yoksa tekrar çekmeyi dene
      if (_encryptionKey == null) {
        await _fetchEncryptionKey(username);
      }

      // Mesajı ChaCha20-Poly1305 ile şifrele
      String payloadText = messageText;
      if (_encryptionKey != null) {
        payloadText = await ChatEncryptionService.encrypt(
          plainText: messageText,
          secretKey: _encryptionKey!,
        );
      }
      
      final payload = {
        'type': 'message',
        'receiver_id': widget.receiverId,
        'message': payloadText,
      };
      
      _channel!.sink.add(jsonEncode(payload));
      
      // Mesaj gidince yazıyor durumunu hemen kapat
      _typingTimer?.cancel();
      _sendTypingStatus(false);
      
      // Kendi ekranımızda düz metni (plain text) gösterelim
      setState(() {
        _messages.insert(0, {
          'sender': username,
          'text': messageText,
          'time': DateFormat('HH:mm').format(DateTime.now()),
        });
      });
      
      // Kendi mesajımızı attığımızda da telefondaki yedeği güncelleyelim (çözülmüş haliyle yerelde saklanır)
      _saveCacheHistory(username);
      
      _controller.clear();
      _scrollToBottom();
    }
  }

  Future<void> _sendMediaPayload(String mediaPayload, String username) async {
    // Soket bağlı değilse yeniden bağlanmayı dene
    if (_channel == null) {
      _connectWebSocket(username);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    final payload = {
      'type': 'message',
      'receiver_id': widget.receiverId,
      'message': mediaPayload,
    };

    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (e) {
      debugPrint("Medya sokete iletilemedi: $e");
    }

    setState(() {
      _messages.insert(0, {
        'sender': username,
        'text': mediaPayload,
        'time': DateFormat('HH:mm').format(DateTime.now()),
      });
    });

    _saveCacheHistory(username);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage(String username) async {
    try {
      File? imageFile;
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final result = await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null && result.files.single.path != null) {
          imageFile = File(result.files.single.path!);
        }
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
        if (picked != null) {
          imageFile = File(picked.path);
        }
      }

      if (imageFile == null) return;
      if (!mounted) return;

      final token = context.read<AuthService>().token;
      setState(() => _isUploadingMedia = true);
      final uploadedUrl = await ApiService.uploadImage(
        ApiConstants.mediaUploadImage,
        imageFile,
        token: token,
      );

      await _sendMediaPayload('[IMAGE]:$uploadedUrl', username);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _pickAndSendAudio(String username) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'caf', 'flac'],
      );

      if (result == null || result.files.single.path == null) return;
      if (!mounted) return;

      final audioFile = File(result.files.single.path!);
      final token = context.read<AuthService>().token;

      setState(() => _isUploadingMedia = true);
      final uploadedUrl = await ApiService.uploadAudio(
        ApiConstants.mediaUploadAudio,
        audioFile,
        token: token,
      );

      await _sendMediaPayload('[AUDIO]:$uploadedUrl', username);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses dosyası yüklenirken hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  void _showAttachmentSheet(String username) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.shade50,
                  child: const Icon(Icons.image, color: Colors.purple),
                ),
                title: const Text('Fotoğraf Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Galeriden veya dosyadan resim seçin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(username);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.shade50,
                  child: const Icon(Icons.audiotrack, color: Colors.orange),
                ),
                title: const Text('Ses Dosyası Gönder', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('MP3, M4A, WAV ses dosyası yükleyin'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendAudio(username);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _typingTimer?.cancel();
    _channel?.sink.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isLoggedIn = auth.isLoggedIn;
    final currentUser = auth.currentUser?.username ?? 'Misafir';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5, // Çok hafif bir gölge
        leadingWidth: 40, // Geri butonuna ayrılan alanı daraltalım
        title: Row(
          children: [
            // Kişinin Avatarı (Profil Fotoğrafı)
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              backgroundImage: widget.receiverAvatar != null 
                  ? NetworkImage(widget.receiverAvatar!)
                  : null,
              child: widget.receiverAvatar == null
                  ? Text(
                      widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // İsim ve "Yazıyor..." Bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName, 
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 17,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // "yazıyor..." efekti
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isOtherTyping
                        ? const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Yazıyor...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.green, // WhatsApp yeşili hissiyatı
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Sağ üste şık ikonlar (Arama ve Seçenekler)
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black54),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isLoggedIn)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              width: double.infinity,
              child: const Text(
                'Sohbete katılmak için lütfen giriş yapın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
              ),
            ),
            
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              reverse: true, // LİSTEYİ TERS ÇEVİRİR (Chat uygulamaları standartı)
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isFetchingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Eğer veri çekiliyorsa ve en son index'teysek (reverse olduğu için bu listenin EN ÜSTÜ demektir) loading göster
                if (_isFetchingMore && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                
                final msg = _messages[index];
                final isMe = msg['sender'] == currentUser;
                return MessageBubble(
                  text: msg['text'] ?? '',
                  isMe: isMe,
                  time: msg['time'] ?? '',
                  senderName: msg['sender'] ?? '',
                );
              },
            ),
          ),
          
          if (_isUploadingMedia)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Medya yükleniyor, lütfen bekleyin...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.black54),
                  tooltip: 'Medya / Ses Gönder',
                  onPressed: (isLoggedIn && _isConnected && !_isUploadingMedia)
                      ? () => _showAttachmentSheet(currentUser)
                      : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: isLoggedIn && _isConnected && !_isUploadingMedia,
                    textInputAction: TextInputAction.send,
                    onChanged: (isLoggedIn && _isConnected) ? _onTextChanged : null,
                    onSubmitted: (_) => (isLoggedIn && _isConnected) ? _sendMessage(currentUser) : null,
                    decoration: InputDecoration(
                      hintText: !isLoggedIn 
                          ? 'Giriş yapmanız gerekiyor' 
                          : _isUploadingMedia
                              ? 'Fotoğraf yükleniyor, lütfen bekleyin...'
                              : !_isConnected 
                                  ? 'İnternet bekleniyor...' 
                                  : 'Bir mesaj yazın...',
                      hintStyle: TextStyle(
                        color: _isUploadingMedia
                            ? Colors.blue.shade700
                            : (!_isConnected ? Colors.red.shade300 : AppTheme.textSecondary),
                      ),
                      filled: true,
                      fillColor: AppTheme.divider.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: (isLoggedIn && _isConnected && !_isUploadingMedia) 
                        ? AppTheme.textPrimary 
                        : AppTheme.divider,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.background, size: 20),
                    onPressed: (isLoggedIn && _isConnected && !_isUploadingMedia) 
                        ? () => _sendMessage(currentUser) 
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final String senderName;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final isImage = text.startsWith('[IMAGE]:');
    final isAudio = text.startsWith('[AUDIO]:');
    final mediaContent = (isImage || isAudio) ? text.substring(8) : text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueAccent,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?', 
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: isImage
                  ? const EdgeInsets.all(6)
                  : const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.green[100] : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isImage)
                    ChatImageWidget(imageUrl: mediaContent, isMe: isMe)
                  else if (isAudio)
                    ChatAudioPlayerWidget(audioUrl: mediaContent, isMe: isMe)
                  else
                    Text(
                      text,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: EdgeInsets.only(right: isImage ? 4.0 : 0.0),
                    child: Text(
                      time,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
