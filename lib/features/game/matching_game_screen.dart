import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_decorative_background.dart';
import '../../core/widgets/bottom_nav.dart';
import 'matching_game_provider.dart';
import 'matching_game_state.dart';

class MatchingGameScreen extends ConsumerWidget {
  const MatchingGameScreen({super.key, this.topic});

  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchingGameProvider(topic));

    ref.listen<MatchingGameState>(matchingGameProvider(topic), (
      previous,
      next,
    ) {
      final previousVersion = previous?.completionDialogVersion ?? 0;

      if (next.completionDialogVersion > previousVersion) {
        _showCompleteDialog(context, ref, next);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AppDecorativeBackground(
        useSafeArea: true,
        child: Column(
          children: [
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    )
                  : state.error != null && state.selectedWords.length < 4
                  ? _GameEmptyState(message: state.error!, topic: topic)
                  : _GameBody(state: state, topic: topic),
            ),
            BottomNav(
              currentIndex: 2,
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
          ],
        ),
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    MatchingGameState state,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
          title: Text('Hoàn thành!', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn đã nối đúng tất cả các từ.',
                textAlign: TextAlign.center,
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.spacing16),
              _DialogRow(
                label: 'Điểm',
                value: '${state.score}/${state.totalPairs}',
              ),
              _DialogRow(label: 'Thời gian', value: state.formattedTime),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(AppRoutes.gameTopics);
              },
              child: Text('Đổi chủ đề', style: AppTheme.pinyin),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonSmallRadius,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(matchingGameProvider(topic).notifier).resetRound();
              },
              child: const Text('Chơi tiếp'),
            ),
          ],
        );
      },
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({required this.state, required this.topic});

  final MatchingGameState state;
  final String? topic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spacing24,
        AppTheme.screenPadding,
        140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GameHeader(),
          const SizedBox(height: AppTheme.spacing28),
          _InfoCard(state: state),
          const SizedBox(height: AppTheme.spacing28),
          _GameBoard(state: state),
          const SizedBox(height: AppTheme.spacing24),
          _ActionButtons(state: state, topic: topic),
          const SizedBox(height: AppTheme.spacing24),
          const _TipCard(),
        ],
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nối từ',
          style: AppTheme.headingXLarge.copyWith(
            color: AppTheme.primary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.spacing10),
        Text(
          'Ghép chữ Hán với nghĩa tiếng Việt',
          style: AppTheme.body.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.state});

  final MatchingGameState state;

  @override
  Widget build(BuildContext context) {
    final topicText = state.topic?.trim().isNotEmpty == true
        ? state.topic!
        : 'Tất cả chủ đề';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _InfoItem(
              icon: Icons.local_florist_outlined,
              label: 'Chủ đề',
              value: topicText,
            ),
          ),
          _InfoDivider(),
          Expanded(
            child: _InfoItem(
              icon: Icons.star_border,
              label: 'Điểm',
              value: '${state.score} / ${state.totalPairs}',
            ),
          ),
          _InfoDivider(),
          Expanded(
            child: _InfoItem(
              icon: Icons.schedule,
              label: 'Thời gian',
              value: state.formattedTime,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 54,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      color: AppTheme.border.withValues(alpha: 0.7),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(width: AppTheme.spacing10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.subtitleMedium),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.headingMedium.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GameBoard extends StatelessWidget {
  const _GameBoard({required this.state});

  final MatchingGameState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _GameColumn(
            titlePrefix: 'Chọn 1 ô ',
            titleHighlight: 'chữ Hán',
            items: state.hanziItems,
            isLeft: true,
            state: state,
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          child: _GameColumn(
            titlePrefix: 'Chọn 1 ô ',
            titleHighlight: 'nghĩa Việt',
            items: state.meaningItems,
            isLeft: false,
            state: state,
          ),
        ),
      ],
    );
  }
}

class _GameColumn extends ConsumerWidget {
  const _GameColumn({
    required this.titlePrefix,
    required this.titleHighlight,
    required this.items,
    required this.isLeft,
    required this.state,
  });

  final String titlePrefix;
  final String titleHighlight;
  final List<MatchingItem> items;
  final bool isLeft;
  final MatchingGameState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(matchingGameProvider(state.topic).notifier);

    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
            children: [
              TextSpan(text: titlePrefix),
              TextSpan(
                text: titleHighlight,
                style: AppTheme.bodyBold.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
            child: _MatchingTile(
              item: item,
              isHanzi: isLeft,
              isMatched: state.isMatched(item.wordId),
              isSelected: isLeft
                  ? state.isSelectedHanzi(item.wordId)
                  : state.isSelectedMeaning(item.wordId),
              isWrong: isLeft
                  ? state.isWrongHanzi(item.wordId)
                  : state.isWrongMeaning(item.wordId),
              isHint: state.isHint(item.wordId),
              onTap: () {
                if (isLeft) {
                  notifier.selectHanzi(item.wordId);
                } else {
                  notifier.selectMeaning(item.wordId);
                }
              },
            ),
          );
        }),
      ],
    );
  }
}

class _MatchingTile extends StatelessWidget {
  const _MatchingTile({
    required this.item,
    required this.isHanzi,
    required this.isMatched,
    required this.isSelected,
    required this.isWrong,
    required this.isHint,
    required this.onTap,
  });

  final MatchingItem item;
  final bool isHanzi;
  final bool isMatched;
  final bool isSelected;
  final bool isWrong;
  final bool isHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showSelected = isSelected || isHint;

    Color borderColor = Colors.transparent;
    Color backgroundColor = AppTheme.surface;

    if (showSelected) {
      borderColor = AppTheme.primary;
      backgroundColor = AppTheme.tagBg.withValues(alpha: 0.65);
    }

    if (isWrong) {
      borderColor = AppTheme.primaryDark;
      backgroundColor = AppTheme.tagBg;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isMatched ? 0.18 : 1,
      child: IgnorePointer(
        ignoring: isMatched,
        child: Material(
          color: backgroundColor,
          borderRadius: AppTheme.cardRadius,
          child: InkWell(
            borderRadius: AppTheme.cardRadius,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 90,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: AppTheme.cardRadius,
                border: Border.all(
                  color: borderColor,
                  width: showSelected || isWrong ? 1.6 : 1,
                ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      item.text,
                      textAlign: TextAlign.center,
                      maxLines: isHanzi ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: isHanzi
                          ? AppTheme.hanziMedium.copyWith(
                              color: AppTheme.primaryDark,
                              fontSize: 30,
                            )
                          : AppTheme.bodyBold.copyWith(
                              fontSize: 17,
                              color: AppTheme.textPrimary,
                            ),
                    ),
                  ),
                  if (showSelected)
                    const Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppTheme.primary,
                        child: Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.state, required this.topic});

  final MatchingGameState state;
  final String? topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(matchingGameProvider(topic).notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 390;

        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SoftButton(
                      icon: Icons.lightbulb_outline,
                      label: 'Gợi ý',
                      badge: '${state.hintCount}',
                      onTap: state.hintCount > 0 ? notifier.useHint : null,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: _SoftButton(
                      icon: Icons.restart_alt,
                      label: 'Chơi lại',
                      isPrimary: true,
                      onTap: notifier.resetRound,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                width: double.infinity,
                child: _SoftButton(
                  icon: Icons.compare_arrows,
                  label: 'Đổi chủ đề',
                  onTap: () => context.go(AppRoutes.gameTopics),
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _SoftButton(
                icon: Icons.lightbulb_outline,
                label: 'Gợi ý',
                badge: '${state.hintCount}',
                onTap: state.hintCount > 0 ? notifier.useHint : null,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _SoftButton(
                icon: Icons.restart_alt,
                label: 'Chơi lại',
                isPrimary: true,
                onTap: notifier.resetRound,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _SoftButton(
                icon: Icons.compare_arrows,
                label: 'Đổi chủ đề',
                onTap: () => context.go(AppRoutes.gameTopics),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? badge;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? AppTheme.primary : AppTheme.surface;
    final fgColor = isPrimary ? Colors.white : AppTheme.primary;

    return SizedBox(
      height: 62,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: isPrimary ? 4 : 0,
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          shadowColor: AppTheme.primary.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: AppTheme.spacing8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyBold.copyWith(color: fgColor),
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -22,
                right: -14,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    badge!,
                    style: AppTheme.tag.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌸 Mẹo nhỏ',
            style: AppTheme.bodyBold.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Hãy chọn một ô chữ Hán bên trái, sau đó chọn nghĩa tương ứng bên phải.',
            style: AppTheme.body.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameEmptyState extends StatelessWidget {
  const _GameEmptyState({required this.message, required this.topic});

  final String message;
  final String? topic;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spacing32,
        AppTheme.screenPadding,
        140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GameHeader(),
          const SizedBox(height: AppTheme.spacing28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.cardLargeRadius,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.extension_off_outlined,
                  color: AppTheme.primary,
                  size: 46,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyBold,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Cần ít nhất 4 từ để tạo ván nối từ.',
                  textAlign: TextAlign.center,
                  style: AppTheme.subtitleMedium,
                ),
                const SizedBox(height: AppTheme.spacing20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppTheme.buttonRadius,
                    ),
                  ),
                  onPressed: () => context.go(AppRoutes.gameTopics),
                  child: const Text('Đổi chủ đề'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.subtitleMedium)),
          Text(value, style: AppTheme.bodyBold),
        ],
      ),
    );
  }
}
