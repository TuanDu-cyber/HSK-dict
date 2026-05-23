import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/topic_model.dart';
import '../../repositories/topic_repository.dart';

enum TopicSelectMode { flashcard, quiz, writing, speaking }

extension TopicSelectModeX on TopicSelectMode {
  String get title {
    switch (this) {
      case TopicSelectMode.flashcard:
        return 'Flashcard';
      case TopicSelectMode.quiz:
        return 'Quiz';
      case TopicSelectMode.writing:
        return 'Writing';
      case TopicSelectMode.speaking:
        return 'Luyện nói';
    }
  }

  String get key {
    switch (this) {
      case TopicSelectMode.flashcard:
        return 'flashcard';
      case TopicSelectMode.quiz:
        return 'quiz';
      case TopicSelectMode.writing:
        return 'writing';
      case TopicSelectMode.speaking:
        return 'speaking';
    }
  }

  String get targetRoute {
    switch (this) {
      case TopicSelectMode.flashcard:
        return '/flashcard';
      case TopicSelectMode.quiz:
        return '/quiz';
      case TopicSelectMode.writing:
        return '/writing';
      case TopicSelectMode.speaking:
        return '/speaking';
    }
  }
}

class TopicSelectItem {
  const TopicSelectItem({
    required this.topic,
    required this.icon,
    required this.iconBackgroundColor,
  });

  final TopicModel topic;
  final IconData icon;
  final Color iconBackgroundColor;
}

final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return const TopicRepository();
});

final topicSelectProvider =
    FutureProvider.family<List<TopicSelectItem>, TopicSelectMode>((
      ref,
      mode,
    ) async {
      final repository = ref.watch(topicRepositoryProvider);

      final topics = await repository.getTopics(modeKey: mode.key);

      return topics.map((topic) {
        return TopicSelectItem(
          topic: topic,
          icon: _getTopicIcon(topic.key),
          iconBackgroundColor: _getTopicColor(topic.key),
        );
      }).toList();
    });

IconData _getTopicIcon(String topic) {
  switch (topic) {
    case 'Feelings & Descriptions':
      return Icons.sentiment_satisfied_alt;
    case 'Numbers & Basics':
      return Icons.looks_3_outlined;
    case 'People & Family':
      return Icons.groups_outlined;
    case 'Daily Life':
      return Icons.home_outlined;
    case 'Places & Directions':
      return Icons.location_on_outlined;
    case 'Food & Drinks':
      return Icons.ramen_dining_outlined;
    case 'Travel & Transportation':
      return Icons.flight_outlined;
    case 'Time & Dates':
      return Icons.calendar_month_outlined;
    case 'Weather & Nature':
      return Icons.wb_sunny_outlined;
    case 'School & Learning':
      return Icons.school_outlined;
    default:
      return Icons.menu_book_outlined;
  }
}

Color _getTopicColor(String topic) {
  switch (topic) {
    case 'Feelings & Descriptions':
      return const Color(0xFFFFC96B);
    case 'Numbers & Basics':
      return const Color(0xFF7BCB6A);
    case 'People & Family':
      return const Color(0xFF9B7BEA);
    case 'Daily Life':
      return const Color(0xFF7FAAF5);
    case 'Places & Directions':
      return const Color(0xFFFF6B6B);
    case 'Food & Drinks':
      return const Color(0xFFFF8A3D);
    case 'Travel & Transportation':
      return const Color(0xFF48C9B0);
    case 'Time & Dates':
      return const Color(0xFFA678E2);
    case 'Weather & Nature':
      return const Color(0xFF5DADE2);
    case 'School & Learning':
      return const Color(0xFF74C365);
    default:
      return const Color(0xFFE8A0A2);
  }
}
