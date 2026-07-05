import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/topic_model.dart';

class TopicRepository {
  const TopicRepository();

  static const List<String> _dataPaths = [
    'assets/data/hsk1.json',
    'assets/data/hsk2.json',
    'assets/data/hsk3.json',
  ];

  static Map<String, int>? _cachedTopicCounts;

  void clearCache() {
    _cachedTopicCounts = null;
  }

  Future<List<TopicModel>> getTopics({required String modeKey}) async {
    final topicCounts = <String, int>{};

    final cachedTopicCounts = _cachedTopicCounts;
    if (cachedTopicCounts != null) {
      topicCounts.addAll(cachedTopicCounts);
    } else {
      for (final path in _dataPaths) {
        try {
          final rawJson = await rootBundle.loadString(path);
          final decoded = jsonDecode(rawJson);

          final List<dynamic> words = _extractWordList(decoded);

          for (final item in words) {
            if (item is! Map<String, dynamic>) continue;

            final topic = item['topic']?.toString().trim();

            if (topic == null || topic.isEmpty) {
              topicCounts['Khác'] = (topicCounts['Khác'] ?? 0) + 1;
            } else {
              topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
            }
          }
        } catch (_) {
          // TODO: Có thể log lỗi đọc JSON ở đây nếu cần.
          // Không throw để app vẫn chạy khi thiếu 1 file data.
        }
      }

      _cachedTopicCounts = Map.unmodifiable(topicCounts);
    }

    final topics = <TopicModel>[];

    for (final entry in topicCounts.entries) {
      final learnedCount = await getLearnedCount(
        modeKey: modeKey,
        topicKey: entry.key,
      );

      topics.add(
        TopicModel(
          key: entry.key,
          title: _getTopicTitle(entry.key),
          subtitle: _getTopicSubtitle(entry.key),
          totalCount: entry.value,
          learnedCount: learnedCount,
        ),
      );
    }

    topics.sort((a, b) {
      final aIndex = _topicOrder.indexOf(a.key);
      final bIndex = _topicOrder.indexOf(b.key);

      if (aIndex == -1 && bIndex == -1) {
        return a.title.compareTo(b.title);
      }

      if (aIndex == -1) return 1;
      if (bIndex == -1) return -1;

      return aIndex.compareTo(bIndex);
    });

    return topics;
  }

  List<dynamic> _extractWordList(dynamic decoded) {
    if (decoded is List) return decoded;

    if (decoded is Map<String, dynamic>) {
      final words = decoded['words'];

      if (words is List) return words;

      final data = decoded['data'];

      if (data is List) return data;
    }

    return [];
  }

  Future<int> getLearnedCount({
    required String modeKey,
    required String topicKey,
  }) async {
    final progressKey = '${modeKey}_${_normalizeKey(topicKey)}';

    // TODO: Sau này nối SQLite/sqflite ở đây.
    // Ví dụ bảng progress:
    // id TEXT PRIMARY KEY: flashcard_daily_life
    // mode TEXT: flashcard
    // topic TEXT: Daily Life
    // learned_count INTEGER
    // updated_at TEXT
    //
    // Hiện tại mock 0 để UI hiển thị 0/totalCount.
    return _mockProgress[progressKey] ?? 0;
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

  String _getTopicTitle(String topic) {
    return _topicNameMap[topic]?.title ?? topic;
  }

  String _getTopicSubtitle(String topic) {
    return _topicNameMap[topic]?.subtitle ?? 'Chủ đề từ vựng';
  }
}

class _TopicName {
  const _TopicName({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const Map<String, _TopicName> _topicNameMap = {
  'Daily Life': _TopicName(
    title: 'Daily Life',
    subtitle: 'Cuộc sống hằng ngày',
  ),
  'Feelings & Descriptions': _TopicName(
    title: 'Feelings & Descriptions',
    subtitle: 'Cảm xúc & Miêu tả',
  ),
  'Numbers & Basics': _TopicName(
    title: 'Numbers & Basics',
    subtitle: 'Số đếm & Cơ bản',
  ),
  'People & Family': _TopicName(
    title: 'People & Family',
    subtitle: 'Con người & Gia đình',
  ),
  'Places & Directions': _TopicName(
    title: 'Places & Directions',
    subtitle: 'Địa điểm & Chỉ đường',
  ),
  'Food & Drinks': _TopicName(
    title: 'Food & Drinks',
    subtitle: 'Đồ ăn & Thức uống',
  ),
  'Travel & Transportation': _TopicName(
    title: 'Travel & Transportation',
    subtitle: 'Du lịch & Giao thông',
  ),
  'Time & Dates': _TopicName(
    title: 'Time & Dates',
    subtitle: 'Thời gian & Ngày tháng',
  ),
  'Weather & Nature': _TopicName(
    title: 'Weather & Nature',
    subtitle: 'Thời tiết & Thiên nhiên',
  ),
  'School & Learning': _TopicName(
    title: 'School & Learning',
    subtitle: 'Trường học & Học tập',
  ),
};

const List<String> _topicOrder = [
  'Feelings & Descriptions',
  'Numbers & Basics',
  'People & Family',
  'Daily Life',
  'Places & Directions',
  'Food & Drinks',
  'Travel & Transportation',
  'Time & Dates',
  'Weather & Nature',
  'School & Learning',
];

const Map<String, int> _mockProgress = {};
