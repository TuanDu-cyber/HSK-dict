import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

final speechRecognitionRepositoryProvider =
    Provider<SpeechRecognitionRepository>((ref) {
      final repository = SpeechRecognitionRepository();

      ref.onDispose(repository.dispose);

      return repository;
    });

class SpeechRecognitionRepository {
  final SpeechToText _speechToText = SpeechToText();

  bool _isInitialized = false;
  String _lastRecognizedText = '';

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    _isInitialized = await _speechToText.initialize(
      onError: (error) {
        // Có thể debug nếu cần:
        // debugPrint('Speech error: $error');
      },
      onStatus: (status) {
        // Có thể debug nếu cần:
        // debugPrint('Speech status: $status');
      },
    );

    return _isInitialized;
  }

  Future<bool> get isAvailable async {
    final initialized = await initialize();

    return initialized && _speechToText.isAvailable;
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    String localeId = 'zh_CN',
  }) async {
    final available = await isAvailable;

    if (!available) {
      throw Exception('Thiết bị chưa hỗ trợ nhận diện giọng nói.');
    }

    final resolvedLocaleId = await _resolveBestLocale(
      preferredLocaleId: localeId,
    );

    _lastRecognizedText = '';

    await _speechToText.stop();

    await _speechToText.listen(
      onResult: (result) {
        _lastRecognizedText = result.recognizedWords.trim();
        onResult(_lastRecognizedText);
      },
      listenOptions: SpeechListenOptions(
        localeId: resolvedLocaleId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        cancelOnError: false,
      ),
    );
  }

  Future<String> stopListening() async {
    await _speechToText.stop();

    return _lastRecognizedText.trim();
  }

  Future<void> cancel() async {
    await _speechToText.cancel();
  }

  Future<String> _resolveBestLocale({required String preferredLocaleId}) async {
    final locales = await _speechToText.locales();

    if (locales.isEmpty) {
      return preferredLocaleId;
    }

    final normalizedPreferred = _normalizeLocale(preferredLocaleId);

    for (final locale in locales) {
      if (_normalizeLocale(locale.localeId) == normalizedPreferred) {
        return locale.localeId;
      }
    }

    for (final locale in locales) {
      final normalized = _normalizeLocale(locale.localeId);

      if (normalized.startsWith('zh')) {
        return locale.localeId;
      }
    }

    final systemLocale = await _speechToText.systemLocale();

    if (systemLocale != null) {
      return systemLocale.localeId;
    }

    return preferredLocaleId;
  }

  String _normalizeLocale(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_');
  }

  void dispose() {
    _speechToText.cancel();
  }
}
