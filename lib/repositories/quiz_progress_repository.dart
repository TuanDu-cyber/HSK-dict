import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final quizProgressRepositoryProvider = Provider<QuizProgressRepository>((ref) {
  return QuizProgressRepository();
});

class QuizProgressData {
  const QuizProgressData({
    required this.currentQuestionIndex,
    required this.selectedAnswerIds,
    required this.correctQuestionIndexes,
    required this.wrongQuestionIndexes,
    required this.skippedQuestionIndexes,
    required this.isCompleted,
    required this.sessionSeed,
  });

  /// currentQuestionIndex bắt đầu từ 0.
  ///
  /// Ví dụ:
  /// - Câu 1/20  => currentQuestionIndex = 0
  /// - Câu 12/20 => currentQuestionIndex = 11
  final int currentQuestionIndex;

  /// key = index câu hỏi, value = wordId user đã chọn.
  final Map<int, String> selectedAnswerIds;

  final Set<int> correctQuestionIndexes;
  final Set<int> wrongQuestionIndexes;
  final Set<int> skippedQuestionIndexes;

  final bool isCompleted;

  /// Dùng để giữ nguyên 1 phiên random.
  ///
  /// Cùng sessionSeed:
  /// - thứ tự câu hỏi giống nhau
  /// - thứ tự đáp án giống nhau
  ///
  /// Khi user bấm "Làm lại từ đầu", provider tạo sessionSeed mới.
  final int sessionSeed;

  Map<String, dynamic> toJson() {
    return {
      'currentQuestionIndex': currentQuestionIndex,
      'selectedAnswerIds': selectedAnswerIds.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'correctQuestionIndexes': correctQuestionIndexes.toList(),
      'wrongQuestionIndexes': wrongQuestionIndexes.toList(),
      'skippedQuestionIndexes': skippedQuestionIndexes.toList(),
      'isCompleted': isCompleted,
      'sessionSeed': sessionSeed,
    };
  }

  factory QuizProgressData.fromJson(Map<String, dynamic> json) {
    return QuizProgressData(
      currentQuestionIndex:
          int.tryParse(json['currentQuestionIndex']?.toString() ?? '') ?? 0,
      selectedAnswerIds: _readSelectedAnswers(json['selectedAnswerIds']),
      correctQuestionIndexes: _readIntSet(json['correctQuestionIndexes']),
      wrongQuestionIndexes: _readIntSet(json['wrongQuestionIndexes']),
      skippedQuestionIndexes: _readIntSet(json['skippedQuestionIndexes']),
      isCompleted: json['isCompleted'] == true,
      sessionSeed: int.tryParse(json['sessionSeed']?.toString() ?? '') ?? 0,
    );
  }

  static Map<int, String> _readSelectedAnswers(dynamic value) {
    if (value is! Map) return {};

    final result = <int, String>{};

    value.forEach((key, answerId) {
      final index = int.tryParse(key.toString());

      if (index != null && answerId != null) {
        result[index] = answerId.toString();
      }
    });

    return result;
  }

  static Set<int> _readIntSet(dynamic value) {
    if (value is! List) return {};

    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toSet();
  }
}

class QuizProgressRepository {
  String _key(String topic) {
    final normalizedTopic = _normalizeTopic(topic);
    return 'quiz_$normalizedTopic';
  }

  String _normalizeTopic(String topic) {
    return topic
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<QuizProgressData?> loadProgress(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(topic));

    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return QuizProgressData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress({
    required String topic,
    required QuizProgressData data,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_key(topic), jsonEncode(data.toJson()));
  }

  Future<void> clearProgress(String topic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(topic));
  }

  /// Dùng cho TopicSelect của Quiz.
  ///
  /// Mục tiêu:
  /// - Chưa từng làm topic => 0/total
  /// - Đang làm câu 1 => 1/total
  /// - Đang làm câu 12 => 12/total
  /// - Hoàn thành câu cuối => total/total
  ///
  /// Tránh lỗi vừa mở quiz lần đầu mà chưa làm gì đã hiện 1/20.
  Future<int> getCurrentQuestionPositionCount(String topic) async {
    final progress = await loadProgress(topic);

    if (progress == null) {
      return 0;
    }

    final hasStarted =
        progress.selectedAnswerIds.isNotEmpty ||
        progress.correctQuestionIndexes.isNotEmpty ||
        progress.wrongQuestionIndexes.isNotEmpty ||
        progress.skippedQuestionIndexes.isNotEmpty ||
        progress.currentQuestionIndex > 0 ||
        progress.isCompleted;

    if (!hasStarted) {
      return 0;
    }

    return progress.currentQuestionIndex + 1;
  }

  /// Dùng nếu sau này muốn hiện số câu đã đúng.
  Future<int> getCorrectCount(String topic) async {
    final progress = await loadProgress(topic);
    return progress?.correctQuestionIndexes.length ?? 0;
  }

  /// Dùng nếu sau này muốn hiện số câu sai.
  Future<int> getWrongCount(String topic) async {
    final progress = await loadProgress(topic);
    return progress?.wrongQuestionIndexes.length ?? 0;
  }

  /// Dùng nếu sau này muốn hiện số câu bỏ qua.
  Future<int> getSkippedCount(String topic) async {
    final progress = await loadProgress(topic);
    return progress?.skippedQuestionIndexes.length ?? 0;
  }

  /// Kiểm tra topic quiz đã hoàn thành chưa.
  Future<bool> isCompleted(String topic) async {
    final progress = await loadProgress(topic);
    return progress?.isCompleted ?? false;
  }
}
