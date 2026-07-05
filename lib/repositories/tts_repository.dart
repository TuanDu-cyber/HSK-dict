import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsRepositoryProvider = Provider<TtsRepository>((ref) {
  final repository = TtsRepository();
  ref.onDispose(() {
    repository.dispose();
  });
  return repository;
});

class TtsRepository {
  TtsRepository();

  final FlutterTts _tts = FlutterTts();

  Future<void> speakChinese(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;

    try {
      await _tts.stop();
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.speak(value);
    } catch (_) {
      try {
        await _tts.speak(value);
      } catch (_) {
        // Ignore TTS failures so unsupported devices do not crash the app.
      }
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore TTS failures so unsupported devices do not crash the app.
    }
  }

  Future<void> dispose() async {
    await stop();
  }
}
