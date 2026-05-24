import '../../models/word_model.dart';

class FlashcardState {
  const FlashcardState({
    required this.topic,
    this.isLoading = false,
    this.error,
    this.words = const [],
    this.currentIndex = 0,
    this.isBackSide = false,
    this.knownWordIds = const {},
    this.unknownWordIds = const {},
    this.favoriteWordIds = const {},
    this.isReviewingUnknown = false,
    this.isCompleted = false,
    this.completionDialogVersion = 0,
  });

  final String topic;
  final bool isLoading;
  final String? error;
  final List<WordModel> words;
  final int currentIndex;
  final bool isBackSide;
  final Set<String> knownWordIds;
  final Set<String> unknownWordIds;
  final Set<String> favoriteWordIds;
  final bool isReviewingUnknown;
  final bool isCompleted;
  final int completionDialogVersion;

  WordModel? get currentWord {
    if (words.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= words.length) return null;
    return words[currentIndex];
  }

  int get totalWords => words.length;

  int get displayIndex {
    if (words.isEmpty) return 0;
    return currentIndex + 1;
  }

  double get progressValue {
    if (words.isEmpty) return 0;
    return displayIndex / words.length;
  }

  bool get isEmpty => !isLoading && error == null && words.isEmpty;

  FlashcardState copyWith({
    String? topic,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<WordModel>? words,
    int? currentIndex,
    bool? isBackSide,
    Set<String>? knownWordIds,
    Set<String>? unknownWordIds,
    Set<String>? favoriteWordIds,
    bool? isReviewingUnknown,
    bool? isCompleted,
    int? completionDialogVersion,
  }) {
    return FlashcardState(
      topic: topic ?? this.topic,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      isBackSide: isBackSide ?? this.isBackSide,
      knownWordIds: knownWordIds ?? this.knownWordIds,
      unknownWordIds: unknownWordIds ?? this.unknownWordIds,
      favoriteWordIds: favoriteWordIds ?? this.favoriteWordIds,
      isReviewingUnknown: isReviewingUnknown ?? this.isReviewingUnknown,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDialogVersion:
          completionDialogVersion ?? this.completionDialogVersion,
    );
  }
}
