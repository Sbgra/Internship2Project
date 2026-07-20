import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/tts_service.dart';

/// Sesli okuma kontrol widget'ı — sadece üyeler görebilir.
class TtsPlayerWidget extends StatefulWidget {
  final String text;
  const TtsPlayerWidget({super.key, required this.text});

  @override
  State<TtsPlayerWidget> createState() => _TtsPlayerWidgetState();
}

class _TtsPlayerWidgetState extends State<TtsPlayerWidget> {
  late final TtsService _tts;

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _tts.addListener(_onTtsChanged);
  }

  void _onTtsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tts.removeListener(_onTtsChanged);
    _tts.dispose();
    super.dispose();
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
            Icons.headphones,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Sesli Dinle',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (_tts.isSpeaking && !_tts.isPaused)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.pause, color: AppTheme.primary),
                  onPressed: _tts.pause,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: AppTheme.error),
                  onPressed: _tts.stop,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            )
          else if (_tts.isPaused)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow, color: AppTheme.primary),
                  onPressed: () => _tts.speak(widget.text),
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  icon: const Icon(Icons.stop, color: AppTheme.error),
                  onPressed: _tts.stop,
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow, color: AppTheme.primary),
              onPressed: () => _tts.speak(widget.text),
              iconSize: 20,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
        ],
      ),
    );
  }
}
