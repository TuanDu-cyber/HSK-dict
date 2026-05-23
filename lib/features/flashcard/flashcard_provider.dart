import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/word_repository.dart';
import 'flashcard_state.dart';

final flashcardProvider =
    StateNotifierProvider.family<FlashcardNotifier, FlashcardState, String>((
      ref,
      topic,
    ) {
      return FlashcardNotifier(
        topic: topic,
        wordRepository: ref.watch(wordRepositoryProvider),
      )..loadWordsByTopic();
    });

class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier({
    required String topic,
    required WordRepository wordRepository,
  }) : _wordRepository = wordRepository,
       super(FlashcardState(topic: topic));

  final WordRepository _wordRepository;

  Future<void> loadWordsByTopic() async {
    try {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        isCompleted: false,
      );

      final words = await _wordRepository.getWordsByTopic(state.topic);

      state = state.copyWith(
        isLoading: false,
        words: words,
        currentIndex: 0,
        isBackSide: false,
        isCompleted: false,
      );
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
  }

  Future<void> markKnownAndNext() async {
    await goNext(known: true);
  }

  Future<void> markUnknownAndNext() async {
    await goNext(known: false);
  }

  Future<void> goNext({required bool known}) async {
    final word = state.currentWord;
    if (word == null || state.isCompleted) return;

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

    state = state.copyWith(
      knownWordIds: knownIds,
      unknownWordIds: unknownIds,
      currentIndex: completed ? state.currentIndex : nextIndex,
      isBackSide: false,
      isCompleted: completed,
    );

    await saveProgress();
  }

  void toggleFavorite(String wordId) {
    final favorites = {...state.favoriteWordIds};

    if (favorites.contains(wordId)) {
      favorites.remove(wordId);
    } else {
      favorites.add(wordId);
    }

    state = state.copyWith(favoriteWordIds: favorites);

    // TODO: Sau này lưu favoriteWordIds vào SQLite/FavoritesRepository.
  }

  Future<void> speakCurrentWord() async {
    final word = state.currentWord;
    if (word == null) return;

    // TODO: Sau này nối flutter_tts ở đây.
    // Ví dụ:
    // await ttsService.speak(word.hanzi);
  }

  Future<void> saveProgress() async {
    final progressKey = 'flashcard_${_normalizeKey(state.topic)}';

    // TODO: Sau này lưu progress vào SQLite/sqflite.
    // Cần lưu:
    // - progressKey
    // - state.currentIndex
    // - state.knownWordIds
    // - state.unknownWordIds
    // - state.favoriteWordIds
    // - DateTime.now()

    progressKey;
  }

  Future<void> resetTopic() async {
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

    await saveProgress();
  }

  String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
