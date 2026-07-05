import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_model.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/tts_repository.dart';
import '../../repositories/word_repository.dart';

final favoritesProvider =
    StateNotifierProvider.autoDispose<
      FavoritesNotifier,
      AsyncValue<List<WordModel>>
    >((ref) {
      return FavoritesNotifier(
        favoritesRepository: ref.watch(favoritesRepositoryProvider),
        wordRepository: ref.watch(wordRepositoryProvider),
      )..loadFavorites();
    });

final favoritesActionsProvider = Provider<FavoritesActions>((ref) {
  return FavoritesActions(
    favoritesRepository: ref.watch(favoritesRepositoryProvider),
    ttsRepository: ref.watch(ttsRepositoryProvider),
  );
});

class FavoritesActions {
  const FavoritesActions({
    required FavoritesRepository favoritesRepository,
    required TtsRepository ttsRepository,
  }) : _favoritesRepository = favoritesRepository,
       _ttsRepository = ttsRepository;

  final FavoritesRepository _favoritesRepository;
  final TtsRepository _ttsRepository;

  Future<void> speakWord(WordModel word) async {
    await _ttsRepository.speakChinese(word.hanzi);
  }

  Future<void> removeWord(WordModel word) async {
    await _favoritesRepository.setFavorite(word.id, false);
  }

  Future<void> restoreWord(WordModel word) async {
    await _favoritesRepository.setFavorite(word.id, true);
  }
}

class FavoritesNotifier extends StateNotifier<AsyncValue<List<WordModel>>> {
  FavoritesNotifier({
    required FavoritesRepository favoritesRepository,
    required WordRepository wordRepository,
  }) : _favoritesRepository = favoritesRepository,
       _wordRepository = wordRepository,
       super(const AsyncValue.loading());

  final FavoritesRepository _favoritesRepository;
  final WordRepository _wordRepository;

  Future<void> loadFavorites() async {
    try {
      state = const AsyncValue.loading();

      final favoriteIds = await _favoritesRepository.getFavoriteIds();
      final words = await _wordRepository.getAllWords();

      state = AsyncValue.data(
        words.where((word) => favoriteIds.contains(word.id)).toList(),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> removeWord(WordModel word) async {
    final previousWords = state.valueOrNull ?? const <WordModel>[];
    final nextWords = previousWords
        .where((item) => item.id != word.id)
        .toList(growable: false);

    state = AsyncValue.data(nextWords);

    try {
      await _favoritesRepository.setFavorite(word.id, false);
    } catch (error) {
      state = AsyncValue.data(previousWords);
      rethrow;
    }
  }

  Future<void> restoreWord(WordModel word) async {
    final previousWords = state.valueOrNull ?? const <WordModel>[];

    if (previousWords.any((item) => item.id == word.id)) {
      return;
    }

    state = AsyncValue.data([...previousWords, word]);

    try {
      await _favoritesRepository.setFavorite(word.id, true);
    } catch (error) {
      state = AsyncValue.data(previousWords);
      rethrow;
    }
  }
}
