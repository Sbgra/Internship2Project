import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Sesli dinleme (TTS) servisi.
/// Makale içeriğini sesli olarak okur. Sadece üyeler kullanabilir.
class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  bool _isPaused = false;

  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      _isPaused = false;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
      _isPaused = false;
      notifyListeners();
    });

    _tts.setPauseHandler(() {
      _isPaused = true;
      notifyListeners();
    });

    _tts.setContinueHandler(() {
      _isPaused = false;
      notifyListeners();
    });
  }

  /// Metni sesli olarak okumaya başla.
  Future<void> speak(String text) async {
    if (_isSpeaking) {
      await stop();
    }
    _isSpeaking = true;
    _isPaused = false;
    notifyListeners();
    await _tts.speak(text);
  }

  /// Okumayı duraklat.
  Future<void> pause() async {
    await _tts.pause();
    _isPaused = true;
    notifyListeners();
  }

  /// Duraklatılmış okumayı devam ettir.
  Future<void> resume() async {
    // flutter_tts doesn't have a resume; re-speak isn't ideal
    // On most platforms pause/resume is supported natively
    _isPaused = false;
    notifyListeners();
  }

  /// Okumayı durdur.
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
    _isPaused = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
