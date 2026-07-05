import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_decorative_background.dart';
import 'auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Chào mừng đến với',
      highlight: 'HSK Dict',
      subtitle:
          'Ứng dụng học từ vựng tiếng Trung giúp bạn luyện Thẻ từ, Kiểm tra, Tập viết, Luyện nói và Nối từ mỗi ngày.',
    ),
    _OnboardingItem(
      title: 'Học HSK dễ dàng',
      highlight: 'Theo chủ đề',
      subtitle:
          'Từ vựng được chia theo chủ đề, giúp bạn ghi nhớ chữ Hán, pinyin và nghĩa tiếng Việt tốt hơn.',
    ),
    _OnboardingItem(
      title: 'Luyện tập mỗi ngày',
      highlight: 'Tiến bộ rõ ràng',
      subtitle:
          'Theo dõi tiến trình học Thẻ từ, Kiểm tra, Tập viết, Luyện nói và Nối từ trong một ứng dụng.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex == _items.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AppDecorativeBackground(
        useSafeArea: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = constraints.maxHeight < 700
                ? AppTheme.spacing8
                : AppTheme.spacing20;
            final buttonHeight = constraints.maxHeight < 620 ? 52.0 : 58.0;

            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPage(item: _items[index]);
                    },
                  ),
                ),
                _DotsIndicator(
                  count: _items.length,
                  currentIndex: _currentIndex,
                ),
                SizedBox(
                  height: constraints.maxHeight < 620
                      ? AppTheme.spacing10
                      : AppTheme.spacing16,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.screenPadding,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 6,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.28),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.buttonRadius,
                        ),
                      ),
                      onPressed: () async {
                        if (!isLast) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOut,
                          );
                          return;
                        }

                        await ref
                            .read(authProvider.notifier)
                            .markOnboardingSeen();
                      },
                      child: Text(
                        isLast ? 'Bắt đầu' : 'Tiếp tục',
                        style: AppTheme.button.copyWith(fontSize: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing6),
                TextButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).markOnboardingSeen();
                  },
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppTheme.primary,
                  ),
                  label: Text(
                    'Đăng nhập ngay',
                    style: AppTheme.bodyBold.copyWith(
                      color: AppTheme.primary,
                      fontSize: 15,
                    ),
                  ),
                ),
                SizedBox(height: bottomPadding),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.highlight,
    required this.subtitle,
  });

  final String title;
  final String highlight;
  final String subtitle;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final compactHeight = height < 560;
        final tinyHeight = height < 500;
        final titleSize = width < 360 ? 30.0 : 34.0;
        final highlightSize = width < 360 ? 42.0 : 50.0;
        final heroSize = (width * 0.55)
            .clamp(150.0, tinyHeight ? 190.0 : 250.0)
            .clamp(0, height * 0.28)
            .toDouble();

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.screenPadding,
            compactHeight ? AppTheme.spacing20 : AppTheme.spacing32,
            AppTheme.screenPadding,
            AppTheme.spacing16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.highlight,
                  maxLines: 1,
                  style: AppTheme.headingXLarge.copyWith(
                    color: AppTheme.primary,
                    fontSize: highlightSize,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                width: width.clamp(0, 310),
                child: Text(
                  item.subtitle,
                  style: AppTheme.body.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: width < 360 ? 15 : 17,
                    height: 1.42,
                  ),
                ),
              ),
              SizedBox(
                height: compactHeight ? AppTheme.spacing12 : AppTheme.spacing20,
              ),
              Center(
                child: SizedBox(
                  width: heroSize,
                  height: heroSize,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '汉',
                      style: AppTheme.hanziLarge.copyWith(
                        fontSize: heroSize * 0.42,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              if (!tinyHeight) ...[
                SizedBox(
                  height: compactHeight
                      ? AppTheme.spacing12
                      : AppTheme.spacing20,
                ),
                _FeaturePreviewRow(compact: compactHeight),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FeaturePreviewRow extends StatelessWidget {
  const _FeaturePreviewRow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final features = [
      const _FeaturePreview(
        icon: Icons.style_outlined,
        title: 'Thẻ từ',
        subtitle: 'Học từ mới\nhiệu quả',
      ),
      const _FeaturePreview(
        icon: Icons.quiz_outlined,
        title: 'Kiểm tra',
        subtitle: 'Kiểm tra nhanh\nghi nhớ lâu',
      ),
      const _FeaturePreview(
        icon: Icons.brush_outlined,
        title: 'Tập viết',
        subtitle: 'Tập viết chữ\nchuẩn đẹp',
      ),
      const _FeaturePreview(
        icon: Icons.mic_none_outlined,
        title: 'Luyện nói',
        subtitle: 'Nói tự tin\nmỗi ngày',
      ),
    ];

    return Row(
      children: features.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing4),
            child: _FeaturePreview(
              icon: item.icon,
              title: item.title,
              subtitle: item.subtitle,
              compact: compact,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FeaturePreview extends StatelessWidget {
  const _FeaturePreview({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 112 : 132,
      padding: EdgeInsets.all(compact ? AppTheme.spacing8 : AppTheme.spacing10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.88),
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: compact ? 40 : 50,
            height: compact ? 40 : 50,
            decoration: const BoxDecoration(
              color: AppTheme.tagBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: compact ? 22 : 26),
          ),
          SizedBox(height: compact ? AppTheme.spacing6 : AppTheme.spacing10),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyBold.copyWith(fontSize: compact ? 12 : 13),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.subtitle.copyWith(
              fontSize: compact ? 10 : 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 12 : 10,
          height: isActive ? 12 : 10,
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
