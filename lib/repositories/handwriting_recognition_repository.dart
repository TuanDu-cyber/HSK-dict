import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final handwritingRecognitionRepositoryProvider =
    Provider<HandwritingRecognitionRepository>((ref) {
  return HandwritingRecognitionRepository();
});

class HandwritingRecognitionResult {
  const HandwritingRecognitionResult({
    required this.candidates,
  });

  final List<String> candidates;

  String? get bestCandidate {
    if (candidates.isEmpty) return null;
    return candidates.first;
  }
}

class HandwritingRecognitionRepository {
  Future<HandwritingRecognitionResult> recognizeChinese({
    required List<List<Offset>> strokes,
    required String expectedText,
  }) async {
    if (strokes.isEmpty) {
      return const HandwritingRecognitionResult(candidates: []);
    }

    // TODO:
    // Nối google_mlkit_digital_ink_recognition ở đây.
    //
    // Ý tưởng:
    // - Convert List<List<Offset>> thành Ink/Strokes theo format của ML Kit.
    // - Download model tiếng Trung nếu chưa có.
    // - Gọi recognizer.recognize(...)
    // - Return candidates.
    //
    // Tạm thời trả rỗng để app không crash.
    return const HandwritingRecognitionResult(candidates: []);
  }
}