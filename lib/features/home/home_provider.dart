import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../repositories/learning_activity_repository.dart';
import '../auth/auth_provider.dart';

class HomeFeatureItem {
  const HomeFeatureItem({
    required this.title,
    required this.subtitle,
    required this.hanzi,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final String hanzi;
  final IconData icon;
  final String route;
}

class HomeState {
  const HomeState({
    required this.displayName,
    required this.avatarUrl,
    required this.avatarAsset,
    required this.onlineMinutesToday,
    required this.currentStreak,
    required this.todayWeekday,
    required this.studiedWeekdays,
    required this.shouldShowReminder,
    required this.weekDays,
    required this.features,
  });

  final String displayName;
  final String? avatarUrl;
  final String avatarAsset;
  final int onlineMinutesToday;
  final int currentStreak;
  final int todayWeekday;
  final Set<int> studiedWeekdays;
  final bool shouldShowReminder;
  final List<String> weekDays;
  final List<HomeFeatureItem> features;

  int get selectedTodayIndex {
    // DateTime.weekday: Monday = 1, Sunday = 7
    return todayWeekday - 1;
  }
}

final homeAsyncProvider = FutureProvider<HomeState>((ref) async {
  final now = DateTime.now();
  final authState = ref.watch(authProvider);
  final learningActivityRepository = ref.watch(
    learningActivityRepositoryProvider,
  );
  final user = authState.user;
  final displayName = user?.name.trim().isNotEmpty == true
      ? user!.name.trim()
      : 'Learner';

  final currentStreak = await learningActivityRepository.getCurrentStreak();
  final studiedWeekdays = await learningActivityRepository.getWeeklyStudyDays();
  final shouldShowReminder = await learningActivityRepository
      .shouldShowReminder();
  final onlineMinutesToday = user?.onlineMinutesToday ?? 0;

  return HomeState(
    displayName: displayName,
    avatarUrl: user?.avatarUrl?.trim().isNotEmpty == true
        ? user!.avatarUrl!.trim()
        : null,
    avatarAsset: 'assets/images/avatar_default.png',
    onlineMinutesToday: onlineMinutesToday,
    currentStreak: currentStreak,
    todayWeekday: now.weekday,
    studiedWeekdays: studiedWeekdays,
    shouldShowReminder: shouldShowReminder,
    weekDays: const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
    features: const [
      HomeFeatureItem(
        title: 'Thẻ từ',
        subtitle: 'Học từ mới',
        hanzi: '汉',
        icon: Icons.style_outlined,
        route: AppRoutes.flashcardTopics,
      ),
      HomeFeatureItem(
        title: 'Kiểm tra',
        subtitle: 'Kiểm tra nhanh',
        hanzi: '测',
        icon: Icons.quiz_outlined,
        route: AppRoutes.quizTopics,
      ),
      HomeFeatureItem(
        title: 'Tập viết',
        subtitle: 'Tập viết chữ',
        hanzi: '写',
        icon: Icons.brush_outlined,
        route: AppRoutes.writingTopics,
      ),
      HomeFeatureItem(
        title: 'Luyện nói',
        subtitle: 'Nói tự tin mỗi ngày',
        hanzi: '说',
        icon: Icons.mic_none_outlined,
        route: AppRoutes.speakingTopics,
      ),
    ],
  );
});
