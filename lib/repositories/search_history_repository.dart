import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user_storage_key_helper.dart';

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>((
  ref,
) {
  return SearchHistoryRepository();
});

class SearchHistoryRepository {
  static const String _keySuffix = 'search_recent_queries';
  static const int _maxItems = 10;

  String get _key => UserStorageKeyHelper.key(_keySuffix);

  Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(_key) ?? const [];
  }

  Future<List<String>> addRecentSearch(String query) async {
    final value = query.trim();

    if (value.isEmpty) {
      return getRecentSearches();
    }

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];

    current.removeWhere(
      (item) => item.trim().toLowerCase() == value.toLowerCase(),
    );

    final updated = [value, ...current].take(_maxItems).toList();

    await prefs.setStringList(_key, updated);

    return updated;
  }

  Future<List<String>> removeRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];

    current.removeWhere(
      (item) => item.trim().toLowerCase() == query.trim().toLowerCase(),
    );

    await prefs.setStringList(_key, current);

    return current;
  }

  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
