import '../../models/word_model.dart';

enum QuizAnswerStatus { none, correct, wrong, skipped }

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.correctWord,
    required this.questionZh,
    required this.questionVi,
    required this.options,
  });

  final String id;
  final WordModel correctWord;
  final String questionZh;
  final String questionVi;
  final List<WordModel> options;

  String get correctWordId => correctWord.id;
}

class QuizState {
  const QuizState({
    required this.topic,
    this.isLoading = false,
    this.error,
    this.questions = const [],
    this.currentIndex = 0,
    this.remainingSeconds = 25,
    this.selectedAnswerIds = const {},
    this.correctQuestionIndexes = const {},
    this.wrongQuestionIndexes = const {},
    this.skippedQuestionIndexes = const {},
    this.isCompleted = false,
    this.completionDialogVersion = 0,
  });

  final String topic;
  final bool isLoading;
  final String? error;

  final List<QuizQuestion> questions;
  final int currentIndex;
  final int remainingSeconds;

  final Map<int, String> selectedAnswerIds;
  final Set<int> correctQuestionIndexes;
  final Set<int> wrongQuestionIndexes;
  final Set<int> skippedQuestionIndexes;

  final bool isCompleted;
  final int completionDialogVersion;

  int get totalQuestions => questions.length;

  int get currentQuestionNumber {
    if (questions.isEmpty) return 0;
    return currentIndex + 1;
  }

  double get progressValue {
    if (totalQuestions == 0) return 0;
    return currentQuestionNumber / totalQuestions;
  }

  int get progressPercent {
    if (totalQuestions == 0) return 0;
    return (progressValue * 100).round();
  }

  int get correctCount => correctQuestionIndexes.length;
  int get wrongCount => wrongQuestionIndexes.length;
  int get skippedCount => skippedQuestionIndexes.length;

  QuizQuestion? get currentQuestion {
    if (questions.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= questions.length) return null;
    return questions[currentIndex];
  }

  String? get selectedAnswerId => selectedAnswerIds[currentIndex];

  bool get hasSelectedCurrentAnswer => selectedAnswerId != null;

  bool get isLastQuestion {
    if (questions.isEmpty) return true;
    return currentIndex >= questions.length - 1;
  }

  QuizAnswerStatus statusOfQuestion(int index) {
    if (correctQuestionIndexes.contains(index)) return QuizAnswerStatus.correct;
    if (wrongQuestionIndexes.contains(index)) return QuizAnswerStatus.wrong;
    if (skippedQuestionIndexes.contains(index)) return QuizAnswerStatus.skipped;
    return QuizAnswerStatus.none;
  }

  bool isSelectedOption(String wordId) {
    return selectedAnswerId == wordId;
  }

  bool isCorrectOption(String wordId) {
    return currentQuestion?.correctWordId == wordId;
  }

  QuizState copyWith({
    String? topic,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<QuizQuestion>? questions,
    int? currentIndex,
    int? remainingSeconds,
    Map<int, String>? selectedAnswerIds,
    Set<int>? correctQuestionIndexes,
    Set<int>? wrongQuestionIndexes,
    Set<int>? skippedQuestionIndexes,
    bool? isCompleted,
    int? completionDialogVersion,
  }) {
    return QuizState(
      topic: topic ?? this.topic,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      selectedAnswerIds: selectedAnswerIds ?? this.selectedAnswerIds,
      correctQuestionIndexes:
          correctQuestionIndexes ?? this.correctQuestionIndexes,
      wrongQuestionIndexes: wrongQuestionIndexes ?? this.wrongQuestionIndexes,
      skippedQuestionIndexes:
          skippedQuestionIndexes ?? this.skippedQuestionIndexes,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDialogVersion:
          completionDialogVersion ?? this.completionDialogVersion,
    );
  }
}
