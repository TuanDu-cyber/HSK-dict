import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/favorites_repository.dart';
import '../../repositories/flashcard_progress_repository.dart';
import '../../repositories/learning_activity_repository.dart';
import '../../repositories/tts_repository.dart';
import '../../repositories/word_repository.dart';
import 'flashcard_state.dart';

// Provider quản lý state thẻ từ, favorite, TTS và tiến trình học theo topic.
final flashcardProvider = StateNotifierProvider.autoDispose
    .family<FlashcardNotifier, FlashcardState, String>((ref, topic) {
      return FlashcardNotifier(
        topic: topic,
        wordRepository: ref.watch(wordRepositoryProvider),
        progressRepository: ref.watch(flashcardProgressRepositoryProvider),
        favoritesRepository: ref.watch(favoritesRepositoryProvider),
        ttsRepository: ref.watch(ttsRepositoryProvider),
        learningActivityRepository: ref.watch(
          learningActivityRepositoryProvider,
        ),
      )..loadWordsByTopic();
    });

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier({
    String topic = '',
    WordRepository? wordRepository,
    FlashcardProgressRepository? progressRepository,
    FavoritesRepository? favoritesRepository,
    TtsRepository? ttsRepository,
    LearningActivityRepository? learningActivityRepository,
  }) : _wordRepository = wordRepository ?? const WordRepository(),
       _progressRepository =
           progressRepository ?? FlashcardProgressRepository(),
       _favoritesRepository = favoritesRepository ?? FavoritesRepository(),
       _ttsRepository = ttsRepository ?? TtsRepository(),
       _learningActivityRepository =
           learningActivityRepository ?? LearningActivityRepository(),
       super(FlashcardState(topic: topic));

  final WordRepository _wordRepository;
  final FlashcardProgressRepository _progressRepository;
  final FavoritesRepository _favoritesRepository;
  final TtsRepository _ttsRepository;
  final LearningActivityRepository _learningActivityRepository;

  Future<void> loadWordsByTopic() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        isCompleted: false,
      );

      final words = await _wordRepository.getWordsByTopic(state.topic);
      final progress = await _progressRepository.loadProgress(state.topic);
      final favoriteIds = await _favoritesRepository.getFavoriteIds();

      final maxIndex = words.isEmpty ? 0 : words.length - 1;
      final savedIndex = progress?.currentIndex ?? 0;
      final safeIndex = savedIndex.clamp(0, maxIndex);

      state = state.copyWith(
        isLoading: false,
        words: words,
        currentIndex: safeIndex,
        isBackSide: false,
        knownWordIds: progress?.knownWordIds ?? {},
        unknownWordIds: progress?.unknownWordIds ?? {},
        favoriteWordIds: favoriteIds,
        isCompleted: false,
      );

      await saveProgress();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải flashcard. Vui lòng kiểm tra dữ liệu.',
      );
    }
  }

  void flipCard() {
    if (state.currentWord == null || state.isCompleted) return;

    state = state.copyWith(isBackSide: !state.isBackSide);

    saveProgress();
  }

  Future<void> markKnownAndNext() async {
    await goNext(known: true);
  }

  Future<void> markUnknownAndNext() async {
    await goNext(known: false);
  }

  Future<void> goNext({required bool known}) async {
    final word = state.currentWord;
    if (word == null) return;

    await _learningActivityRepository.markStudiedToday();

    final knownIds = {...state.knownWordIds};
    final unknownIds = {...state.unknownWordIds};

    if (known) {
      knownIds.add(word.id);
      unknownIds.remove(word.id);
    } else {
      unknownIds.add(word.id);
      knownIds.remove(word.id);
    }

    final nextIndex = state.currentIndex + 1;
    final completed = nextIndex >= state.words.length;
    final newIndex = completed ? state.currentIndex : nextIndex;

    state = state.copyWith(
      knownWordIds: knownIds,
      unknownWordIds: unknownIds,
      currentIndex: newIndex,
      isBackSide: false,
      isCompleted: completed,
      completionDialogVersion: completed
          ? state.completionDialogVersion + 1
          : state.completionDialogVersion,
    );

    await saveProgress();
  }

  Future<void> toggleFavorite(String wordId) async {
    final favorites = await _favoritesRepository.toggleFavorite(wordId);

    state = state.copyWith(favoriteWordIds: favorites);
  }

  Future<void> speakCurrentWord() async {
    final word = state.currentWord;
    if (word == null) return;

    await _ttsRepository.speakChinese(word.hanzi);
  }

  Future<void> saveProgress() async {
    await _progressRepository.saveProgress(
      topic: state.topic,
      data: FlashcardProgressData(
        currentIndex: state.currentIndex,
        knownWordIds: state.knownWordIds,
        unknownWordIds: state.unknownWordIds,
        favoriteWordIds: const {},
      ),
    );
  }

  Future<void> resetTopic() async {
    await _progressRepository.clearProgress(state.topic);

    state = state.copyWith(
      currentIndex: 0,
      isBackSide: false,
      knownWordIds: {},
      unknownWordIds: {},
      isCompleted: false,
      isReviewingUnknown: false,
    );

    await saveProgress();
  }

  Future<void> reviewUnknownWords() async {
    final unknownWords = state.words
        .where((word) => state.unknownWordIds.contains(word.id))
        .toList();

    if (unknownWords.isEmpty) {
      await resetTopic();
      return;
    }

    state = state.copyWith(
      words: unknownWords,
      currentIndex: 0,
      isBackSide: false,
      isCompleted: false,
      isReviewingUnknown: true,
    );
  }
}
