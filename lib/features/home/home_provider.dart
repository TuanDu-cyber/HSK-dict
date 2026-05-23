import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    required this.weekDays,
    required this.features,
  });

  final String displayName;
  final String? avatarUrl;
  final String avatarAsset;
  final int onlineMinutesToday;
  final int currentStreak;
  final int todayWeekday;
  final List<String> weekDays;
  final List<HomeFeatureItem> features;

  int get selectedTodayIndex {
    // DateTime.weekday: Monday = 1, Sunday = 7
    return todayWeekday - 1;
  }
}

final homeProvider = Provider<HomeState>((ref) {
  final now = DateTime.now();

  return HomeState(
    displayName: 'learner',
    avatarUrl: null,
    avatarAsset: 'assets/images/avatar_default.png',
    onlineMinutesToday: 1,
    currentStreak: 1,
    todayWeekday: now.weekday,
    weekDays: const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
    features: const [
      HomeFeatureItem(
        title: 'Flashcard',
        subtitle: 'Học từ mới',
        hanzi: '汉',
        icon: Icons.style_outlined,
        route: '/flashcard/topics',
      ),
      HomeFeatureItem(
        title: 'Quiz',
        subtitle: 'Kiểm tra nhanh',
        hanzi: '测',
        icon: Icons.quiz_outlined,
        route: '/quiz/topics',
      ),
      HomeFeatureItem(
        title: 'Writing',
        subtitle: 'Tập viết chữ',
        hanzi: '写',
        icon: Icons.brush_outlined,
        route: '/writing/topics',
      ),
      HomeFeatureItem(
        title: 'Luyện nói',
        subtitle: 'Nói tự tin mỗi ngày',
        hanzi: '说',
        icon: Icons.mic_none_outlined,
        route: '/speaking/topics',
      ),
    ],
  );
});
