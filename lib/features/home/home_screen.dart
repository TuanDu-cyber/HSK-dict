import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/app_decorative_background.dart';
import '../../repositories/notification_repository.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeAsyncProvider);

    ref.listen<AsyncValue<HomeState>>(homeAsyncProvider, (previous, next) {
      final homeState = next.valueOrNull;
      if (homeState == null) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(notificationRepositoryProvider).scheduleDailyStreakReminder();
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AppDecorativeBackground(
        useSafeArea: true,
        child: homeAsync.when(
          data: (homeState) => _HomeContent(homeState: homeState),
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          ),
          error: (_, _) => const Center(
            child: Text('Không thể tải trang chủ.', style: AppTheme.body),
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 0,
        items: const [
          BottomNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
          BottomNavItem(icon: Icons.search_outlined, label: 'Tìm kiếm'),
          BottomNavItem(icon: Icons.menu_book_outlined, label: 'Nối từ'),
          BottomNavItem(icon: Icons.person_outline, label: 'Cài đặt'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.go(AppRoutes.search);
              break;
            case 2:
              context.go(AppRoutes.gameTopics);
              break;
            case 3:
              context.go(AppRoutes.account);
              break;
          }
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.homeState});

  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spacing20,
        AppTheme.screenPadding,
        AppTheme.spacing24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeader(homeState: homeState),
          const SizedBox(height: AppTheme.spacing24),
          _StreakCard(homeState: homeState),
          const SizedBox(height: AppTheme.spacing24),
          _FeatureGrid(features: homeState.features),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.homeState});

  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ch\u00e0o, ${homeState.displayName} \u{1F44B}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.headingLarge,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Hôm nay bạn muốn học gì?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.subtitleMedium.copyWith(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        GestureDetector(
          onTap: () => context.push(AppRoutes.account),
          child: _Avatar(
            avatarUrl: homeState.avatarUrl,
            avatarAsset: homeState.avatarAsset,
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatarUrl, required this.avatarAsset});

  final String? avatarUrl;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    final imageProvider = avatarUrl != null && avatarUrl!.isNotEmpty
        ? NetworkImage(avatarUrl!)
        : AssetImage(avatarAsset) as ImageProvider;

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        shape: BoxShape.circle,
      ),
      child: CircleAvatar(
        backgroundColor: AppTheme.iconSoftBg,
        backgroundImage: imageProvider,
        onBackgroundImageError: (_, _) {},
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.homeState});

  final HomeState homeState;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        border: Border.all(color: AppTheme.primary, width: 1.5),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            child: Row(
              children: [
                _FireStreakIcon(streak: homeState.currentStreak),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giữ streak mỗi ngày',
                        style: AppTheme.headingMedium,
                      ),
                      const SizedBox(height: AppTheme.spacing6),
                      Text(
                        'Học mỗi ngày để giữ chuỗi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.subtitleMedium.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                const _GiftIcon(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacing16,
              AppTheme.spacing16,
              AppTheme.spacing16,
              AppTheme.spacing16,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppTheme.radiusCardLarge),
                bottomRight: Radius.circular(AppTheme.radiusCardLarge),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing10,
                vertical: AppTheme.spacing14,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: AppTheme.cardRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(homeState.weekDays.length, (index) {
                  final isToday = index == homeState.selectedTodayIndex;

                  return Expanded(
                    child: _WeekDayItem(
                      label: homeState.weekDays[index],
                      isToday: isToday,
                      isStudied: homeState.studiedWeekdays.contains(index + 1),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FireStreakIcon extends StatelessWidget {
  const _FireStreakIcon({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/fire.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return const Icon(
                Icons.local_fire_department,
                size: 64,
                color: AppTheme.primary,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing14),
            child: Text(
              '$streak',
              style: AppTheme.headingLarge.copyWith(
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftIcon extends StatelessWidget {
  const _GiftIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.iconSoftBg,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.45),
          width: 1.2,
        ),
      ),
      child: const Icon(
        Icons.card_giftcard_rounded,
        color: AppTheme.primary,
        size: 36,
      ),
    );
  }
}

class _WeekDayItem extends StatelessWidget {
  const _WeekDayItem({
    required this.label,
    required this.isToday,
    required this.isStudied,
  });

  final String label;
  final bool isToday;
  final bool isStudied;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isStudied ? AppTheme.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isStudied || isToday
                  ? AppTheme.primary
                  : AppTheme.borderMedium,
              width: 1.4,
            ),
          ),
          child: isStudied
              ? const Icon(Icons.check, color: Colors.white, size: 24)
              : null,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          label,
          style: AppTheme.bodyBold.copyWith(
            color: isToday ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.features});

  final List<HomeFeatureItem> features;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppTheme.spacing12;
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: features.map((feature) {
            return SizedBox(
              width: itemWidth,
              child: _FeatureCard(feature: feature),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final HomeFeatureItem feature;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.cardLargeRadius,
      child: InkWell(
        borderRadius: AppTheme.cardLargeRadius,
        onTap: () {
          context.push(feature.route);
        },
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardLargeRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                top: 0,
                child: Text(
                  feature.hanzi,
                  style: AppTheme.hanziMedium.copyWith(
                    fontSize: 38,
                    color: AppTheme.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    'assets/images/cloud_mountain.png',
                    width: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: const BoxDecoration(
                      color: AppTheme.iconSoftBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      feature.icon,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    feature.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyBold.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          feature.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.subtitleMedium,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.iconSoftBg,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: AppTheme.primary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
