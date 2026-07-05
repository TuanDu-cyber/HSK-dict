import 'package:flutter/material.dart';

import '../../models/word_model.dart';

enum WritingWordStatus { none, completed, wrong, skipped }

class WritingState {
  const WritingState({
    required this.topic,
    this.isLoading = false,
    this.error,
    this.words = const [],
    this.currentIndex = 0,
    this.currentCharIndex = 0,
    this.sessionSeed = 0,
    this.completedCharIds = const {},
    this.wrongCharIds = const {},
    this.skippedCharIds = const {},
    this.attemptCountByCharId = const {},
    this.strokes = const [],
    this.showAnswer = false,
    this.isRecognizing = false,
    this.recognizedText,
    this.isCompleted = false,
    this.completionDialogVersion = 0,
  });

  final String topic;
  final bool isLoading;
  final String? error;

  /// Danh sách từ trong phiên writing.
  /// Ví dụ: 希望, 没有, 出租车...
  final List<WordModel> words;

  /// Index của từ hiện tại.
  final int currentIndex;

  /// Index của chữ Hán hiện tại trong từ.
  /// Ví dụ 希望:
  /// currentCharIndex = 0 => 希
  /// currentCharIndex = 1 => 望
  final int currentCharIndex;

  final int sessionSeed;

  /// Lưu theo từng ký tự, không lưu theo cả từ.
  /// Ví dụ:
  /// hsk2_001_char_0
  /// hsk2_001_char_1
  final Set<String> completedCharIds;
  final Set<String> wrongCharIds;
  final Set<String> skippedCharIds;
  final Map<String, int> attemptCountByCharId;

  final List<List<Offset>> strokes;
  final bool showAnswer;
  final bool isRecognizing;
  final String? recognizedText;

  final bool isCompleted;
  final int completionDialogVersion;

  WordModel? get currentWord {
    if (words.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= words.length) return null;
    return words[currentIndex];
  }

  List<String> get currentCharacters {
    final word = currentWord;
    if (word == null) return [];

    return word.hanzi.characters.toList();
  }

  String? get currentCharacter {
    final chars = currentCharacters;

    if (chars.isEmpty) return null;
    if (currentCharIndex < 0 || currentCharIndex >= chars.length) {
      return chars.first;
    }

    return chars[currentCharIndex];
  }

  String? get currentCharId {
    final word = currentWord;
    final char = currentCharacter;

    if (word == null || char == null) return null;

    return '${word.id}_char_$currentCharIndex';
  }

  bool get isLastWord {
    if (words.isEmpty) return true;
    return currentIndex >= words.length - 1;
  }

  bool get isLastCharacterInWord {
    final chars = currentCharacters;
    if (chars.isEmpty) return true;

    return currentCharIndex >= chars.length - 1;
  }

  bool get isLastCharacterInSession {
    return isLastWord && isLastCharacterInWord;
  }

  int get totalWords => words.length;

  int get totalCharacters {
    var total = 0;

    for (final word in words) {
      total += word.hanzi.characters.length;
    }

    return total;
  }

  int get currentQuestionNumber {
    if (words.isEmpty) return 0;

    var count = 0;

    for (var i = 0; i < currentIndex; i++) {
      count += words[i].hanzi.characters.length;
    }

    return count + currentCharIndex + 1;
  }

  double get progressValue {
    if (totalCharacters <= 0) return 0;
    return currentQuestionNumber / totalCharacters;
  }

  int get progressPercent {
    return (progressValue * 100).round();
  }

  int get completedCount => completedCharIds.length;
  int get wrongCount => wrongCharIds.length;
  int get skippedCount => skippedCharIds.length;

  List<String> charIdsOfWord(int index) {
    if (index < 0 || index >= words.length) return [];

    final word = words[index];
    final chars = word.hanzi.characters.toList();

    return List.generate(
      chars.length,
      (charIndex) => '${word.id}_char_$charIndex',
    );
  }

  WritingWordStatus statusOfWord(int index) {
    final charIds = charIdsOfWord(index);

    if (charIds.isEmpty) return WritingWordStatus.none;

    final allCompleted = charIds.every(completedCharIds.contains);
    if (allCompleted) return WritingWordStatus.completed;

    final hasWrong = charIds.any(wrongCharIds.contains);
    if (hasWrong) return WritingWordStatus.wrong;

    final hasSkipped = charIds.any(skippedCharIds.contains);
    if (hasSkipped) return WritingWordStatus.skipped;

    final hasCompleted = charIds.any(completedCharIds.contains);
    if (hasCompleted) return WritingWordStatus.completed;

    return WritingWordStatus.none;
  }

  WritingState copyWith({
    String? topic,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<WordModel>? words,
    int? currentIndex,
    int? currentCharIndex,
    int? sessionSeed,
    Set<String>? completedCharIds,
    Set<String>? wrongCharIds,
    Set<String>? skippedCharIds,
    Map<String, int>? attemptCountByCharId,
    List<List<Offset>>? strokes,
    bool? showAnswer,
    bool? isRecognizing,
    String? recognizedText,
    bool clearRecognizedText = false,
    bool? isCompleted,
    int? completionDialogVersion,
  }) {
    return WritingState(
      topic: topic ?? this.topic,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      currentCharIndex: currentCharIndex ?? this.currentCharIndex,
      sessionSeed: sessionSeed ?? this.sessionSeed,
      completedCharIds: completedCharIds ?? this.completedCharIds,
      wrongCharIds: wrongCharIds ?? this.wrongCharIds,
      skippedCharIds: skippedCharIds ?? this.skippedCharIds,
      attemptCountByCharId: attemptCountByCharId ?? this.attemptCountByCharId,
      strokes: strokes ?? this.strokes,
      showAnswer: showAnswer ?? this.showAnswer,
      isRecognizing: isRecognizing ?? this.isRecognizing,
      recognizedText: clearRecognizedText
          ? null
          : recognizedText ?? this.recognizedText,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDialogVersion:
          completionDialogVersion ?? this.completionDialogVersion,
    );
  }
}
