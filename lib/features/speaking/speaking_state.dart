import '../../models/word_model.dart';

enum SpeakingWordStatus { none, completed, lowScore, skipped }

class SpeakingScore {
  const SpeakingScore({
    required this.totalScore,
    required this.initialScore,
    required this.finalScore,
    required this.toneScore,
    required this.feedback,
  });

  final int totalScore;
  final int initialScore;
  final int finalScore;
  final int toneScore;
  final String feedback;

  bool get isGood => totalScore >= 80;
}

class SpeakingState {
  const SpeakingState({
    required this.topic,
    this.isLoading = false,
    this.error,
    this.words = const [],
    this.currentIndex = 0,
    this.sessionSeed = 0,
    this.isRecording = false,
    this.isRecognizing = false,
    this.recordDuration = Duration.zero,
    this.recognizedText,
    this.scoreByWordId = const {},
    this.initialScoreByWordId = const {},
    this.finalScoreByWordId = const {},
    this.toneScoreByWordId = const {},
    this.feedbackByWordId = const {},
    this.recognizedTextByWordId = const {},
    this.completedWordIds = const {},
    this.lowScoreWordIds = const {},
    this.skippedWordIds = const {},
    this.audioPathByWordId = const {},
    this.isCompleted = false,
    this.completionDialogVersion = 0,
  });

  final String topic;
  final bool isLoading;
  final String? error;

  final List<WordModel> words;
  final int currentIndex;
  final int sessionSeed;

  final bool isRecording;
  final bool isRecognizing;
  final Duration recordDuration;
  final String? recognizedText;

  final Map<String, int> scoreByWordId;
  final Map<String, int> initialScoreByWordId;
  final Map<String, int> finalScoreByWordId;
  final Map<String, int> toneScoreByWordId;
  final Map<String, String> feedbackByWordId;
  final Map<String, String> recognizedTextByWordId;
  final Map<String, String> audioPathByWordId;

  final Set<String> completedWordIds;
  final Set<String> lowScoreWordIds;
  final Set<String> skippedWordIds;

  final bool isCompleted;
  final int completionDialogVersion;

  WordModel? get currentWord {
    if (words.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= words.length) return null;
    return words[currentIndex];
  }

  int get totalWords => words.length;

  int get currentQuestionNumber {
    if (words.isEmpty) return 0;
    return currentIndex + 1;
  }

  double get progressValue {
    if (totalWords == 0) return 0;
    return currentQuestionNumber / totalWords;
  }

  int get progressPercent {
    return (progressValue * 100).round();
  }

  bool get isLastQuestion {
    if (words.isEmpty) return true;
    return currentIndex >= words.length - 1;
  }

  bool get hasResultForCurrentWord {
    final word = currentWord;
    if (word == null) return false;
    return scoreByWordId.containsKey(word.id);
  }

  int get currentScore {
    final word = currentWord;
    if (word == null) return 0;
    return scoreByWordId[word.id] ?? 0;
  }

  int get currentInitialScore {
    final word = currentWord;
    if (word == null) return 0;
    return initialScoreByWordId[word.id] ?? 0;
  }

  int get currentFinalScore {
    final word = currentWord;
    if (word == null) return 0;
    return finalScoreByWordId[word.id] ?? 0;
  }

  int get currentToneScore {
    final word = currentWord;
    if (word == null) return 0;
    return toneScoreByWordId[word.id] ?? 0;
  }

  String get currentFeedback {
    final word = currentWord;
    if (word == null) return '';
    return feedbackByWordId[word.id] ?? '';
  }

  String? get currentSavedRecognizedText {
    final word = currentWord;
    if (word == null) return null;
    return recognizedTextByWordId[word.id];
  }

  String? get currentAudioPath {
    final word = currentWord;
    if (word == null) return null;
    return audioPathByWordId[word.id];
  }

  int get completedCount => completedWordIds.length;
  int get lowScoreCount => lowScoreWordIds.length;
  int get skippedCount => skippedWordIds.length;

  int get averageScore {
    if (scoreByWordId.isEmpty) return 0;

    final total = scoreByWordId.values.fold<int>(
      0,
      (sum, score) => sum + score,
    );

    return (total / scoreByWordId.length).round();
  }

  SpeakingWordStatus statusOfWord(int index) {
    if (index < 0 || index >= words.length) return SpeakingWordStatus.none;

    final wordId = words[index].id;

    if (completedWordIds.contains(wordId)) {
      return SpeakingWordStatus.completed;
    }

    if (lowScoreWordIds.contains(wordId)) {
      return SpeakingWordStatus.lowScore;
    }

    if (skippedWordIds.contains(wordId)) {
      return SpeakingWordStatus.skipped;
    }

    return SpeakingWordStatus.none;
  }

  SpeakingState copyWith({
    String? topic,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<WordModel>? words,
    int? currentIndex,
    int? sessionSeed,
    bool? isRecording,
    bool? isRecognizing,
    Duration? recordDuration,
    String? recognizedText,
    bool clearRecognizedText = false,
    Map<String, int>? scoreByWordId,
    Map<String, int>? initialScoreByWordId,
    Map<String, int>? finalScoreByWordId,
    Map<String, int>? toneScoreByWordId,
    Map<String, String>? feedbackByWordId,
    Map<String, String>? recognizedTextByWordId,
    Map<String, String>? audioPathByWordId,
    Set<String>? completedWordIds,
    Set<String>? lowScoreWordIds,
    Set<String>? skippedWordIds,
    bool? isCompleted,
    int? completionDialogVersion,
  }) {
    return SpeakingState(
      topic: topic ?? this.topic,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      sessionSeed: sessionSeed ?? this.sessionSeed,
      isRecording: isRecording ?? this.isRecording,
      isRecognizing: isRecognizing ?? this.isRecognizing,
      recordDuration: recordDuration ?? this.recordDuration,
      recognizedText: clearRecognizedText
          ? null
          : recognizedText ?? this.recognizedText,
      scoreByWordId: scoreByWordId ?? this.scoreByWordId,
      initialScoreByWordId: initialScoreByWordId ?? this.initialScoreByWordId,
      finalScoreByWordId: finalScoreByWordId ?? this.finalScoreByWordId,
      toneScoreByWordId: toneScoreByWordId ?? this.toneScoreByWordId,
      feedbackByWordId: feedbackByWordId ?? this.feedbackByWordId,
      recognizedTextByWordId:
          recognizedTextByWordId ?? this.recognizedTextByWordId,
      audioPathByWordId: audioPathByWordId ?? this.audioPathByWordId,
      completedWordIds: completedWordIds ?? this.completedWordIds,
      lowScoreWordIds: lowScoreWordIds ?? this.lowScoreWordIds,
      skippedWordIds: skippedWordIds ?? this.skippedWordIds,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDialogVersion:
          completionDialogVersion ?? this.completionDialogVersion,
    );
  }
}
