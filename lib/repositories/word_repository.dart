import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_model.dart';

final wordRepositoryProvider = Provider<WordRepository>((ref) {
  return const WordRepository();
});

class WordRepository {
  const WordRepository();

  static const List<String> _dataPaths = [
    'assets/data/hsk1.json',
    'assets/data/hsk2.json',
  ];

  Future<List<WordModel>> getAllWords() async {
    final allWords = <WordModel>[];

    for (final path in _dataPaths) {
      try {
        final rawJson = await rootBundle.loadString(path);
        final decoded = jsonDecode(rawJson);

        final List<dynamic> wordList = _extractWordList(decoded);

        final words = wordList
            .whereType<Map<String, dynamic>>()
            .map(WordModel.fromJson)
            .where((word) => word.id.isNotEmpty && word.hanzi.isNotEmpty)
            .toList();

        allWords.addAll(words);
      } catch (e) {
        // TODO: Có thể log lỗi đọc file JSON nếu cần.
        // Không throw để app không crash nếu 1 file bị thiếu/lỗi.
      }
    }

    return allWords;
  }

  Future<List<WordModel>> getWordsByTopic(String topic) async {
    final words = await getAllWords();

    final normalizedTopic = topic.trim().toLowerCase();

    return words.where((word) {
      return word.topic.trim().toLowerCase() == normalizedTopic;
    }).toList();
  }

  Future<List<WordModel>> getWordsByLevel(int level) async {
    final words = await getAllWords();

    return words.where((word) => word.level == level).toList();
  }

  Future<List<WordModel>> searchWords(String query) async {
    final words = await getAllWords();
    final keyword = query.trim().toLowerCase();

    if (keyword.isEmpty) return words;

    return words.where((word) {
      return word.hanzi.toLowerCase().contains(keyword) ||
          word.pinyin.toLowerCase().contains(keyword) ||
          word.meaningVi.toLowerCase().contains(keyword) ||
          word.category.toLowerCase().contains(keyword) ||
          word.topic.toLowerCase().contains(keyword);
    }).toList();
  }

  List<dynamic> _extractWordList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final words = decoded['words'];
      if (words is List) return words;

      final data = decoded['data'];
      if (data is List) return data;
    }

    return [];
  }
}
