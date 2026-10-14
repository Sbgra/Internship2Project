import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

/// URL'i platforma göre normalize eder (Android emülatör vs Desktop/Web).
String resolveMediaUrl(String rawUrl) {
  String url = rawUrl.trim();
  if (url.startsWith('/')) {
    url = '${ApiConstants.baseUrl}$url';
  }
  
  if (!kIsWeb) {
    if (Platform.isAndroid) {
      if (url.contains('localhost:8000')) {
        url = url.replaceAll('localhost:8000', '10.0.2.2:8000');
      } else if (url.contains('127.0.0.1:8000')) {
        url = url.replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
      }
    } else {
      if (url.contains('10.0.2.2:8000')) {
        url = url.replaceAll('10.0.2.2:8000', '127.0.0.1:8000');
      }
    }
  }
  return url;
}

/// Sohbette gönderilen görselleri gösteren ve tıklandığında büyüten widget.
class ChatImageWidget extends StatelessWidget {
  final String imageUrl;
  final bool isMe;

  const ChatImageWidget({
    super.key,
    required this.imageUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = resolveMediaUrl(imageUrl);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      resolvedUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 240,
            maxHeight: 260,
          ),
          color: Colors.black12,
          child: Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 160,
                width: 220,
                color: Colors.black.withOpacity(0.04),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 120,
                width: 200,
                color: Colors.grey.shade200,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.grey, size: 36),
                    SizedBox(height: 6),
                    Text(
                      'Resim yüklenemedi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Sohbette gönderilen ses dosyalarını oynatan ses balonu widget'ı.
class ChatAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;

  const ChatAudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
  });

  @override
  State<ChatAudioPlayerWidget> createState() => _ChatAudioPlayerWidgetState();
}

class _ChatAudioPlayerWidgetState extends State<ChatAudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (_isPlaying) _isLoading = false;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() => _duration = dur);
      }
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final resolvedUrl = resolveMediaUrl(widget.audioUrl);
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        await _audioPlayer.play(UrlSource(resolvedUrl));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ses çalınamadı: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMe ? Colors.green.shade800 : AppTheme.primary;
    final totalDuration = _duration > Duration.zero ? _duration : const Duration(seconds: 1);
    final currentPos = _position <= totalDuration ? _position : totalDuration;

    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Butonu
          InkWell(
            onTap: _toggleAudio,
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: activeColor,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Slider ve Süre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                    activeTrackColor: activeColor,
                    inactiveTrackColor: Colors.black12,
                    thumbColor: activeColor,
                  ),
                  child: Slider(
                    min: 0.0,
                    max: totalDuration.inMilliseconds.toDouble(),
                    value: currentPos.inMilliseconds.toDouble().clamp(
                          0.0,
                          totalDuration.inMilliseconds.toDouble(),
                        ),
                    onChanged: (val) async {
                      final newPos = Duration(milliseconds: val.toInt());
                      await _audioPlayer.seek(newPos);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.mic, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 2),
                          Text(
                            _duration > Duration.zero ? _formatDuration(_duration) : 'Ses',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
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
