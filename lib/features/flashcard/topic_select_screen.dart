import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../core/widgets/decorative_background.dart';
import '../../core/widgets/topic_card.dart';
import 'topic_select_provider.dart';

class TopicSelectScreen extends ConsumerWidget {
  const TopicSelectScreen({super.key, this.mode = TopicSelectMode.flashcard});

  final TopicSelectMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicSelectProvider(mode));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: DecorativeBackground(
        // Asset dự kiến:
        // cherryBlossomAsset: 'assets/images/cherry_branch.png'
        // lanternAsset: 'assets/images/lantern.png'
        // mountainAsset: 'assets/images/cloud_mountain.png'
        cherryBlossomAsset: 'assets/images/cherry_branch.png',
        lanternAsset: null,
        mountainAsset: 'assets/images/cloud_mountain.png',
        showCherry: true,
        showLantern: false,
        showCloud: false,
        showMountain: true,
        child: Column(
          children: [
            Padding(
              padding: AppTheme.screenHorizontalPadding,
              child: AppBarCustom(
                title: mode.title,
                actionIcon: Icons.help_outline,
                onBack: () => context.go(AppRoutes.home),
                onAction: () => _showHelpDialog(context),
              ),
            ),
            Expanded(
              child: topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) {
                    return const _EmptyTopicView();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.screenPadding,
                      AppTheme.spacing24,
                      AppTheme.screenPadding,
                      120,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _TopicHeader(),
                        const SizedBox(height: AppTheme.spacing28),
                        _TopicGrid(mode: mode, topics: topics),
                      ],
                    ),
                  );
                },
                loading: () => const _LoadingView(),
                error: (error, stackTrace) {
                  return _ErrorView(
                    message: 'Không thể tải danh sách chủ đề.',
                    onRetry: () {
                      ref.invalidate(topicSelectProvider(mode));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 0,
        items: const [
          BottomNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
          BottomNavItem(icon: Icons.search_outlined, label: 'Tìm kiếm'),
          BottomNavItem(icon: Icons.translate_outlined, label: 'Dịch'),
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
              context.go(AppRoutes.translate);
              break;
            case 3:
              context.go(AppRoutes.account);
              break;
          }
        },
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
          title: Text('Hướng dẫn', style: AppTheme.headingMedium),
          content: Text(
            'Chọn một chủ đề để bắt đầu luyện tập. Tiến trình sẽ được tính riêng cho từng chế độ học.',
            style: AppTheme.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đã hiểu', style: AppTheme.pinyin),
            ),
          ],
        );
      },
    );
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacing12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn chủ đề',
                  style: AppTheme.headingXLarge.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing10),
                Text(
                  'Học từ vựng theo chủ đề để ghi nhớ dễ dàng hơn',
                  style: AppTheme.subtitleMedium.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Image.asset(
          'assets/images/flashcard_header.png',
          width: 130,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 110,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.iconSoftBg,
                borderRadius: AppTheme.cardRadius,
              ),
              child: Center(child: Text('汉', style: AppTheme.hanziMedium)),
            );
          },
        ),
      ],
    );
  }
}

class _TopicGrid extends StatelessWidget {
  const _TopicGrid({required this.mode, required this.topics});

  final TopicSelectMode mode;
  final List<TopicSelectItem> topics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final int crossAxisCount;
        final double cardHeight;

        if (width < 330) {
          crossAxisCount = 1;
          cardHeight = 155;
        } else if (width < 390) {
          crossAxisCount = 2;
          cardHeight = 188;
        } else if (width < 430) {
          crossAxisCount = 2;
          cardHeight = 178;
        } else {
          crossAxisCount = 2;
          cardHeight = 168;
        }

        return GridView.builder(
          itemCount: topics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacing12,
            mainAxisSpacing: AppTheme.spacing12,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, index) {
            final item = topics[index];

            return TopicCard(
              index: index + 1,
              title: item.topic.title,
              subtitle: item.topic.subtitle,
              icon: item.icon,
              iconBackgroundColor: item.iconBackgroundColor,
              progressValue: item.topic.progressValue,
              progressText: item.topic.progressText,
              compact: width < 390,
              onTap: () {
                final encodedTopic = Uri.encodeComponent(item.topic.key);
                context.push('${mode.targetRoute}?topic=$encodedTopic');
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primary),
    );
  }
}

class _EmptyTopicView extends StatelessWidget {
  const _EmptyTopicView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPaddingAll,
        child: Text(
          'Chưa có dữ liệu chủ đề.\nHãy kiểm tra assets/data/hsk1.json và assets/data/hsk2.json.',
          textAlign: TextAlign.center,
          style: AppTheme.body,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPaddingAll,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center, style: AppTheme.body),
            const SizedBox(height: AppTheme.spacing16),
            TextButton(
              onPressed: onRetry,
              child: Text('Thử lại', style: AppTheme.pinyin),
            ),
          ],
        ),
      ),
    );
  }
}
