import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsRepositoryProvider = Provider<TtsRepository>((ref) {
  return TtsRepository();
});

class TtsRepository {
  TtsRepository();

  final FlutterTts _tts = FlutterTts();

  Future<void> speakChinese(String text) async {
    if (text.trim().isEmpty) return;

    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}