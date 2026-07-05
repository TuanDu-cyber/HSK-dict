import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/topic_model.dart';
import '../../repositories/flashcard_progress_repository.dart';
import '../../repositories/quiz_progress_repository.dart';
import '../../repositories/topic_repository.dart';
import '../../repositories/writing_progress_repository.dart';
import '../../repositories/speaking_progress_repository.dart';

enum TopicSelectMode { flashcard, quiz, writing, speaking, game }

extension TopicSelectModeX on TopicSelectMode {
  String get title {
    switch (this) {
      case TopicSelectMode.flashcard:
      case TopicSelectMode.quiz:
      case TopicSelectMode.writing:
      case TopicSelectMode.speaking:
      case TopicSelectMode.game:
        return 'Chọn chủ đề';
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
      case TopicSelectMode.game:
        return 'game';
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
      case TopicSelectMode.game:
        return '/game';
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

final topicSelectProvider = FutureProvider.autoDispose
    .family<List<TopicSelectItem>, TopicSelectMode>((ref, mode) async {
      final topicRepository = ref.watch(topicRepositoryProvider);

      final flashcardProgressRepository = ref.watch(
        flashcardProgressRepositoryProvider,
      );

      final quizProgressRepository = ref.watch(quizProgressRepositoryProvider);

      final writingProgressRepository = ref.watch(
        writingProgressRepositoryProvider,
      );
      final speakingProgressRepository = ref.watch(
        speakingProgressRepositoryProvider,
      );
      final topics = await topicRepository.getTopics(modeKey: mode.key);

      final items = <TopicSelectItem>[];

      for (final topic in topics) {
        int totalCount = topic.totalCount;
        int progressCount = topic.learnedCount;

        if (mode == TopicSelectMode.flashcard) {
          progressCount = await flashcardProgressRepository
              .getCurrentPositionCount(topic.key);

          if (progressCount > totalCount) {
            progressCount = totalCount;
          }
        }

        if (mode == TopicSelectMode.quiz) {
          // Quiz chỉ lấy tối đa 20 câu, nên Topic Quiz cũng phải hiện /20.
          totalCount = topic.totalCount > 20 ? 20 : topic.totalCount;

          progressCount = await quizProgressRepository
              .getCurrentQuestionPositionCount(topic.key);

          if (progressCount > totalCount) {
            progressCount = totalCount;
          }
        }

        if (mode == TopicSelectMode.writing) {
          totalCount = topic.totalCount > 20 ? 20 : topic.totalCount;

          progressCount = await writingProgressRepository
              .getCurrentPositionCount(topic.key);

          if (progressCount > totalCount) {
            progressCount = totalCount;
          }
        }

        if (mode == TopicSelectMode.speaking) {
          totalCount = topic.totalCount > 20 ? 20 : topic.totalCount;

          progressCount = await speakingProgressRepository
              .getCurrentPositionCount(topic.key);

          if (progressCount > totalCount) {
            progressCount = totalCount;
          }
        }

        final updatedTopic = topic.copyWith(
          totalCount: totalCount,
          learnedCount: progressCount,
        );

        items.add(
          TopicSelectItem(
            topic: updatedTopic,
            icon: _getTopicIcon(topic.key),
            iconBackgroundColor: _getTopicColor(topic.key),
          ),
        );
      }

      return items;
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
    case 'Health & Body':
      return Icons.monitor_heart_outlined;
    case 'Work & Career':
      return Icons.work_outline;
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
    case 'Health & Body':
      return const Color(0xFFE96D8B);
    case 'Work & Career':
      return const Color(0xFF6C8AE4);
    default:
      return const Color(0xFFE8A0A2);
  }
}
