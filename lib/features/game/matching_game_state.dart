import '../../models/word_model.dart';

enum MatchingItemType { hanzi, meaning }

class MatchingItem {
  const MatchingItem({
    required this.wordId,
    required this.text,
    required this.type,
  });

  final String wordId;
  final String text;
  final MatchingItemType type;
}

class MatchingGameState {
  const MatchingGameState({
    this.isLoading = false,
    this.error,
    this.topic,
    this.selectedWords = const [],
    this.hanziItems = const [],
    this.meaningItems = const [],
    this.selectedHanziId,
    this.selectedMeaningId,
    this.matchedWordIds = const {},
    this.wrongHanziId,
    this.wrongMeaningId,
    this.hintWordId,
    this.hintCount = 3,
    this.elapsedSeconds = 0,
    this.isCompleted = false,
    this.completionDialogVersion = 0,
  });

  final bool isLoading;
  final String? error;
  final String? topic;

  final List<WordModel> selectedWords;
  final List<MatchingItem> hanziItems;
  final List<MatchingItem> meaningItems;

  final String? selectedHanziId;
  final String? selectedMeaningId;

  final Set<String> matchedWordIds;

  final String? wrongHanziId;
  final String? wrongMeaningId;

  final String? hintWordId;

  final int hintCount;
  final int elapsedSeconds;

  final bool isCompleted;
  final int completionDialogVersion;

  int get score => matchedWordIds.length;

  int get totalPairs => selectedWords.length;

  bool get hasEnoughWords => selectedWords.length >= 4;

  double get progressValue {
    if (totalPairs <= 0) return 0;
    return score / totalPairs;
  }

  String get formattedTime {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;

    final minuteText = minutes.toString().padLeft(2, '0');
    final secondText = seconds.toString().padLeft(2, '0');

    return '$minuteText:$secondText';
  }

  bool isMatched(String wordId) {
    return matchedWordIds.contains(wordId);
  }

  bool isSelectedHanzi(String wordId) {
    return selectedHanziId == wordId;
  }

  bool isSelectedMeaning(String wordId) {
    return selectedMeaningId == wordId;
  }

  bool isWrongHanzi(String wordId) {
    return wrongHanziId == wordId;
  }

  bool isWrongMeaning(String wordId) {
    return wrongMeaningId == wordId;
  }

  bool isHint(String wordId) {
    return hintWordId == wordId;
  }

  MatchingGameState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? topic,
    bool clearTopic = false,
    List<WordModel>? selectedWords,
    List<MatchingItem>? hanziItems,
    List<MatchingItem>? meaningItems,
    String? selectedHanziId,
    bool clearSelectedHanziId = false,
    String? selectedMeaningId,
    bool clearSelectedMeaningId = false,
    Set<String>? matchedWordIds,
    String? wrongHanziId,
    bool clearWrongHanziId = false,
    String? wrongMeaningId,
    bool clearWrongMeaningId = false,
    String? hintWordId,
    bool clearHintWordId = false,
    int? hintCount,
    int? elapsedSeconds,
    bool? isCompleted,
    int? completionDialogVersion,
  }) {
    return MatchingGameState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      topic: clearTopic ? null : topic ?? this.topic,
      selectedWords: selectedWords ?? this.selectedWords,
      hanziItems: hanziItems ?? this.hanziItems,
      meaningItems: meaningItems ?? this.meaningItems,
      selectedHanziId: clearSelectedHanziId
          ? null
          : selectedHanziId ?? this.selectedHanziId,
      selectedMeaningId: clearSelectedMeaningId
          ? null
          : selectedMeaningId ?? this.selectedMeaningId,
      matchedWordIds: matchedWordIds ?? this.matchedWordIds,
      wrongHanziId: clearWrongHanziId
          ? null
          : wrongHanziId ?? this.wrongHanziId,
      wrongMeaningId: clearWrongMeaningId
          ? null
          : wrongMeaningId ?? this.wrongMeaningId,
      hintWordId: clearHintWordId ? null : hintWordId ?? this.hintWordId,
      hintCount: hintCount ?? this.hintCount,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDialogVersion:
          completionDialogVersion ?? this.completionDialogVersion,
    );
  }
}
