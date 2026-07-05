import '../../models/word_model.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.allWords = const [],
    this.results = const [],
    this.recentSearches = const [],
    this.selectedTopic,
    this.selectedLevel,
    this.onlySaved = false,
    this.favoriteWordIds = const {},
    this.isLoading = false,
    this.error,
  });

  final String query;
  final List<WordModel> allWords;
  final List<WordModel> results;
  final List<String> recentSearches;

  final String? selectedTopic;
  final int? selectedLevel;
  final bool onlySaved;

  final Set<String> favoriteWordIds;

  final bool isLoading;
  final String? error;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasActiveFilter {
    return selectedTopic != null || selectedLevel != null || onlySaved;
  }

  List<String> get availableTopics {
    final topics = allWords
        .map((word) => word.topic.trim())
        .where((topic) => topic.isNotEmpty)
        .toSet()
        .toList();

    topics.sort();

    return topics;
  }

  SearchState copyWith({
    String? query,
    List<WordModel>? allWords,
    List<WordModel>? results,
    List<String>? recentSearches,
    String? selectedTopic,
    bool clearSelectedTopic = false,
    int? selectedLevel,
    bool clearSelectedLevel = false,
    bool? onlySaved,
    Set<String>? favoriteWordIds,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      allWords: allWords ?? this.allWords,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      selectedTopic: clearSelectedTopic
          ? null
          : selectedTopic ?? this.selectedTopic,
      selectedLevel: clearSelectedLevel
          ? null
          : selectedLevel ?? this.selectedLevel,
      onlySaved: onlySaved ?? this.onlySaved,
      favoriteWordIds: favoriteWordIds ?? this.favoriteWordIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}
