import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/auth_service.dart';

class TtsPlayerWidget extends StatefulWidget {
  final int articleId;
  final String? text;
  final String lang;
  const TtsPlayerWidget({
    super.key,
    required this.articleId,
    this.text,
    this.lang = 'tr',
  });

  @override
  State<TtsPlayerWidget> createState() => _TtsPlayerWidgetState();
}

class _TtsPlayerWidgetState extends State<TtsPlayerWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastErrorTime;

  Timer? _statusTimer;
  bool _isAudioReady = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) _isLoading = false;
        });
      }
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
    _player.onLog.listen((msg) {
      if (mounted && (msg.contains('error') || msg.contains('Error'))) {
        debugPrint('[TTS Player] Log: $msg');
      }
    });
    
    // Sesin hazır olup olmadığını kontrol et
    _checkAudioStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_isAudioReady) {
        _checkAudioStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkAudioStatus() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/articles/${widget.articleId}/audio-status'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        bool allReady = data['all_ready'] ?? true;
        
        // Backend'in kullandığı dil kodunu bul (Orijinal ise tr)
        String checkLang = widget.lang;
        if (checkLang.toLowerCase() == 'orijinal' || checkLang.toLowerCase() == 'türkçe') {
          checkLang = 'tr';
        }
        
        final status = data[checkLang];
        if (status == 'ready' && allReady) {
          if (mounted) {
            setState(() {
              _isAudioReady = true;
            });
            _statusTimer?.cancel();
          }
        } else if (status != null && status.toString().startsWith('error')) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Ses oluşturulamadı';
            });
            _statusTimer?.cancel();
          }
        }
      }
    } catch (e) {
      debugPrint("Audio status check failed: $e");
    }
  }

  @override
  void didUpdateWidget(TtsPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lang != widget.lang) {
      _stop();
      setState(() {
        _isAudioReady = false;
        _errorMessage = null;
      });
      _statusTimer?.cancel();
      _checkAudioStatus();
      _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!_isAudioReady) {
          _checkAudioStatus();
        } else {
          timer.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (!_isAudioReady) return; // Hazır değilse hiçbir şey yapma

    if (_isPlaying) {
      await _player.pause();
      return;
    }

    if (_lastErrorTime != null &&
        DateTime.now().difference(_lastErrorTime!).inSeconds < 30) {
      final remaining =
          30 - DateTime.now().difference(_lastErrorTime!).inSeconds;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lütfen $remaining saniye sonra tekrar deneyin.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = context.read<AuthService>().token;
      String url =
          '${ApiConstants.baseUrl}/articles/${widget.articleId}/audio?lang=${Uri.encodeComponent(widget.lang)}';
      if (token != null) {
        url += '&token=$token';
      }

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode >= 400) {
        String detail = 'Ses oluşturulamadı';
        try {
          final body = jsonDecode(response.body);
          detail = body['detail'] ?? detail;
        } catch (_) {}

        setState(() {
          _isLoading = false;
          _errorMessage = detail;
          _lastErrorTime = DateTime.now();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(detail),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
        return;
      }

      await _player.play(UrlSource(url));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastErrorTime = DateTime.now();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Icon(
            !_isAudioReady
                ? Icons.hourglass_empty
                : Icons.headphones,
            color: _errorMessage != null 
                ? AppTheme.error 
                : (!_isAudioReady ? AppTheme.textSecondary : AppTheme.primary),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage != null
                  ? 'Ses yüklenemedi — tekrar deneyin'
                  : (!_isAudioReady 
                      ? 'Sesler hazırlanıyor...' 
                      : 'Sesli Dinle (Yapay Zeka)'),
              style: TextStyle(
                color: _errorMessage != null
                    ? AppTheme.error
                    : (!_isAudioReady ? AppTheme.textSecondary : AppTheme.textPrimary),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (_isLoading || !_isAudioReady)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary,
                ),
              ),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPlaying)
                  IconButton(
                    onPressed: _stop,
                    icon: const Icon(Icons.stop_circle_outlined),
                    color: AppTheme.error,
                    tooltip: 'Durdur',
                  ),
                IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  color: _errorMessage != null
                      ? AppTheme.error
                      : AppTheme.primary,
                  iconSize: 36,
                  tooltip: _isPlaying ? 'Duraklat' : 'Oynat',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
