import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/word_model.dart';
import '../../repositories/favorites_repository.dart';
import '../../repositories/search_history_repository.dart';
import '../../repositories/tts_repository.dart';
import '../../repositories/word_repository.dart';
import 'search_state.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier(
    wordRepository: ref.watch(wordRepositoryProvider),
    historyRepository: ref.watch(searchHistoryRepositoryProvider),
    favoritesRepository: ref.watch(favoritesRepositoryProvider),
    ttsRepository: ref.watch(ttsRepositoryProvider),
  )..loadInitialData();
});

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier({
    required WordRepository wordRepository,
    required SearchHistoryRepository historyRepository,
    required FavoritesRepository favoritesRepository,
    required TtsRepository ttsRepository,
  }) : _wordRepository = wordRepository,
       _historyRepository = historyRepository,
       _favoritesRepository = favoritesRepository,
       _ttsRepository = ttsRepository,
       super(const SearchState(isLoading: true));

  final WordRepository _wordRepository;
  final SearchHistoryRepository _historyRepository;
  final FavoritesRepository _favoritesRepository;
  final TtsRepository _ttsRepository;

  Future<void> loadInitialData() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final words = await _wordRepository.getAllWords();
      final recentSearches = await _historyRepository.getRecentSearches();
      final favoriteIds = await _favoritesRepository.getFavoriteIds();

      state = state.copyWith(
        isLoading: false,
        allWords: words,
        recentSearches: recentSearches,
        favoriteWordIds: favoriteIds,
        results: const [],
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Không thể tải dữ liệu tìm kiếm.',
      );
    }
  }

  void updateQuery(String value) {
    state = state.copyWith(query: value);
    _runSearch(saveHistory: false);
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query);
    await submitSearch();
  }

  void clearQuery() {
    state = state.copyWith(query: '', results: const []);

    _runSearch(saveHistory: false);
  }

  Future<void> submitSearch() async {
    final query = state.query.trim();

    if (query.isNotEmpty) {
      final recent = await _historyRepository.addRecentSearch(query);
      state = state.copyWith(recentSearches: recent);
    }

    _runSearch(saveHistory: false);
  }

  Future<void> addRecentSearch(String query) async {
    final recent = await _historyRepository.addRecentSearch(query);
    state = state.copyWith(recentSearches: recent);
  }

  Future<void> removeRecentSearch(String query) async {
    final recent = await _historyRepository.removeRecentSearch(query);
    state = state.copyWith(recentSearches: recent);
  }

  Future<void> clearRecentSearches() async {
    await _historyRepository.clearRecentSearches();
    state = state.copyWith(recentSearches: const []);
  }

  void applyTopicFilter(String? topic) {
    state = state.copyWith(
      selectedTopic: topic,
      clearSelectedTopic: topic == null,
    );

    _runSearch(saveHistory: false);
  }

  void applyLevelFilter(int? level) {
    state = state.copyWith(
      selectedLevel: level,
      clearSelectedLevel: level == null,
    );

    _runSearch(saveHistory: false);
  }

  void setOnlySaved(bool value) {
    state = state.copyWith(onlySaved: value);
    _runSearch(saveHistory: false);
  }

  void toggleOnlySaved() {
    state = state.copyWith(onlySaved: !state.onlySaved);
    _runSearch(saveHistory: false);
  }

  void clearFilters() {
    state = state.copyWith(
      clearSelectedTopic: true,
      clearSelectedLevel: true,
      onlySaved: false,
    );

    _runSearch(saveHistory: false);
  }

  Future<void> speakWord(WordModel word) async {
    await _ttsRepository.speakChinese(word.hanzi);
  }

  Future<void> toggleFavorite(String wordId) async {
    final favoriteIds = await _favoritesRepository.toggleFavorite(wordId);

    state = state.copyWith(favoriteWordIds: favoriteIds);

    _runSearch(saveHistory: false);
  }

  void _runSearch({required bool saveHistory}) {
    final query = state.query.trim();

    var words = [...state.allWords];

    if (state.selectedTopic != null) {
      words = words
          .where((word) => word.topic.trim() == state.selectedTopic)
          .toList();
    }

    if (state.selectedLevel != null) {
      words = words.where((word) => word.level == state.selectedLevel).toList();
    }

    if (state.onlySaved) {
      words = words
          .where((word) => state.favoriteWordIds.contains(word.id))
          .toList();
    }

    if (query.isNotEmpty) {
      words = words.where((word) => _matchesQuery(word, query)).toList();
    } else if (!state.hasActiveFilter) {
      words = const [];
    }

    state = state.copyWith(results: words);
  }

  bool _matchesQuery(WordModel word, String rawQuery) {
    final query = _normalizeSearch(rawQuery);
    final compactQuery = query.replaceAll(' ', '');

    if (query.isEmpty) return true;

    final hskLevel = _parseHskLevel(query);

    if (hskLevel != null) {
      return word.level == hskLevel;
    }

    final hanzi = _normalizeSearch(word.hanzi);
    final pinyin = _normalizeSearch(word.pinyin);
    final compactPinyin = pinyin.replaceAll(' ', '');
    final meaning = _normalizeSearch(word.meaningVi);
    final topic = _normalizeSearch(word.topic);
    final category = _normalizeSearch(word.category);
    final levelText = _normalizeSearch('hsk ${word.level} hsk${word.level}');

    return hanzi.contains(query) ||
        pinyin.contains(query) ||
        compactPinyin.contains(compactQuery) ||
        meaning.contains(query) ||
        topic.contains(query) ||
        category.contains(query) ||
        levelText.contains(query);
  }

  int? _parseHskLevel(String query) {
    final normalized = query.replaceAll(' ', '');

    if (!normalized.startsWith('hsk')) return null;

    final numberText = normalized.replaceFirst('hsk', '');

    return int.tryParse(numberText);
  }

  String _normalizeSearch(String value) {
    return _removeVietnameseTone(
      _removePinyinTone(value),
    ).toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _removePinyinTone(String value) {
    return value
        .replaceAll(RegExp(r'[āáǎàăắằẳẵặâấầẩẫậ]'), 'a')
        .replaceAll(RegExp(r'[ĀÁǍÀĂẮẰẲẴẶÂẤẦẨẪẬ]'), 'A')
        .replaceAll(RegExp(r'[ēéěèêếềểễệ]'), 'e')
        .replaceAll(RegExp(r'[ĒÉĚÈÊẾỀỂỄỆ]'), 'E')
        .replaceAll(RegExp(r'[īíǐì]'), 'i')
        .replaceAll(RegExp(r'[ĪÍǏÌ]'), 'I')
        .replaceAll(RegExp(r'[ōóǒòôốồổỗộơớờởỡợ]'), 'o')
        .replaceAll(RegExp(r'[ŌÓǑÒÔỐỒỔỖỘƠỚỜỞỠỢ]'), 'O')
        .replaceAll(RegExp(r'[ūúǔùưứừửữự]'), 'u')
        .replaceAll(RegExp(r'[ŪÚǓÙƯỨỪỬỮỰ]'), 'U')
        .replaceAll(RegExp(r'[ǖǘǚǜü]'), 'u')
        .replaceAll(RegExp(r'[ǕǗǙǛÜ]'), 'U');
  }

  String _removeVietnameseTone(String value) {
    return value
        .replaceAll(RegExp(r'[áàảãạăắằẳẵặâấầẩẫậ]'), 'a')
        .replaceAll(RegExp(r'[ÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ]'), 'A')
        .replaceAll(RegExp(r'[éèẻẽẹêếềểễệ]'), 'e')
        .replaceAll(RegExp(r'[ÉÈẺẼẸÊẾỀỂỄỆ]'), 'E')
        .replaceAll(RegExp(r'[íìỉĩị]'), 'i')
        .replaceAll(RegExp(r'[ÍÌỈĨỊ]'), 'I')
        .replaceAll(RegExp(r'[óòỏõọôốồổỗộơớờởỡợ]'), 'o')
        .replaceAll(RegExp(r'[ÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ]'), 'O')
        .replaceAll(RegExp(r'[úùủũụưứừửữự]'), 'u')
        .replaceAll(RegExp(r'[ÚÙỦŨỤƯỨỪỬỮỰ]'), 'U')
        .replaceAll(RegExp(r'[ýỳỷỹỵ]'), 'y')
        .replaceAll(RegExp(r'[ÝỲỶỸỴ]'), 'Y')
        .replaceAll('đ', 'd')
        .replaceAll('Đ', 'D');
  }
}
