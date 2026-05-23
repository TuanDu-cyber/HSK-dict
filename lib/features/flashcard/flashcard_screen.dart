import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';
import 'flashcard_provider.dart';
import 'flashcard_state.dart';
import '../../models/word_model.dart';

class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashcardProvider(topic));

    ref.listen<FlashcardState>(flashcardProvider(topic), (previous, next) {
      if (previous?.isCompleted == false && next.isCompleted) {
        _showCompleteDialog(context, ref, next);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: AppTheme.screenHorizontalPadding,
          child: Column(
            children: [
              AppBarCustom(
                title: 'Flashcard',
                actionIcon: Icons.bookmark_border,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.flashcardTopics);
                  }
                },
                onAction: () {
                  // TODO: mở danh sách từ đã lưu.
                },
              ),
              const SizedBox(height: AppTheme.spacing20),
              Expanded(
                child: _FlashcardBody(topic: topic, state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    FlashcardState state,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
          title: Text('Hoàn thành chủ đề!', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Bạn đã học xong ${state.topic}', style: AppTheme.body),
              const SizedBox(height: AppTheme.spacing16),
              _CompleteStatRow(
                label: 'Đã thuộc',
                value: '${state.knownWordIds.length} từ',
              ),
              _CompleteStatRow(
                label: 'Chưa thuộc',
                value: '${state.unknownWordIds.length} từ',
              ),
              _CompleteStatRow(label: 'Tổng', value: '${state.totalWords} từ'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.flashcardTopics);
                }
              },
              child: Text('Quay lại chủ đề', style: AppTheme.pinyin),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(flashcardProvider(topic).notifier).resetTopic();
              },
              child: Text('Học lại', style: AppTheme.pinyin),
            ),
            ElevatedButton(
              onPressed: state.unknownWordIds.isEmpty
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      ref
                          .read(flashcardProvider(topic).notifier)
                          .reviewUnknownWords();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.primaryLight.withOpacity(
                  0.45,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              child: const Text('Ôn lại từ chưa thuộc', style: AppTheme.button),
            ),
          ],
        );
      },
    );
  }
}

class _FlashcardBody extends ConsumerWidget {
  const _FlashcardBody({required this.topic, required this.state});

  final String topic;
  final FlashcardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () {
          ref.invalidate(flashcardProvider(topic));
        },
      );
    }

    if (state.isEmpty) {
      return _EmptyView(topic: topic);
    }

    final word = state.currentWord;
    if (word == null) {
      return _EmptyView(topic: topic);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight < 620
            ? constraints.maxHeight * 0.58
            : constraints.maxHeight * 0.68;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppTheme.spacing24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProgressHeaderRow(state: state),
                const SizedBox(height: AppTheme.spacing8),
                _LinearProgress(value: state.progressValue),
                const SizedBox(height: AppTheme.spacing32),
                _SwipeCardArea(
                  topic: topic,
                  state: state,
                  cardHeight: cardHeight.clamp(360, 520).toDouble(),
                ),
                const SizedBox(height: AppTheme.spacing20),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app_outlined,
                        color: AppTheme.textSecondary,
                        size: 22,
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        'Gạt sang trái hoặc phải',
                        style: AppTheme.subtitleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing32),
                const _SwipeHintRow(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressHeaderRow extends StatelessWidget {
  const _ProgressHeaderRow({required this.state});

  final FlashcardState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${state.topic} 🍲',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.headingMedium,
          ),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Text(
          '${state.displayIndex} / ${state.totalWords}',
          style: AppTheme.headingMedium,
        ),
      ],
    );
  }
}

class _LinearProgress extends StatelessWidget {
  const _LinearProgress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: AppTheme.primaryLight.withOpacity(0.45),
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
      ),
    );
  }
}

class _SwipeCardArea extends ConsumerStatefulWidget {
  const _SwipeCardArea({
    required this.topic,
    required this.state,
    required this.cardHeight,
  });

  final String topic;
  final FlashcardState state;
  final double cardHeight;

  @override
  ConsumerState<_SwipeCardArea> createState() => _SwipeCardAreaState();
}

class _SwipeCardAreaState extends ConsumerState<_SwipeCardArea> {
  double _dragX = 0;

  static const double _threshold = 80;

  @override
  Widget build(BuildContext context) {
    final word = widget.state.currentWord!;

    return GestureDetector(
      onTap: () {
        ref.read(flashcardProvider(widget.topic).notifier).flipCard();
      },
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragX += details.delta.dx;
        });
      },
      onHorizontalDragEnd: (_) async {
        final notifier = ref.read(flashcardProvider(widget.topic).notifier);

        if (_dragX > _threshold) {
          await notifier.markKnownAndNext();
        } else if (_dragX < -_threshold) {
          await notifier.markUnknownAndNext();
        }

        if (mounted) {
          setState(() {
            _dragX = 0;
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 0,
            top: 24,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              decoration: BoxDecoration(
                color: _dragX >= 0
                    ? AppTheme.success.withOpacity(0.18)
                    : AppTheme.primaryLight.withOpacity(0.55),
                borderRadius: AppTheme.cardLargeRadius,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            transform: Matrix4.identity()
              ..translate(_dragX)
              ..rotateZ(_dragX / 900),
            child: SizedBox(
              height: widget.cardHeight,
              width: double.infinity,
              child: _FlashcardMainCard(
                topic: widget.topic,
                word: word,
                isBackSide: widget.state.isBackSide,
                isFavorite: widget.state.favoriteWordIds.contains(word.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardMainCard extends ConsumerWidget {
  const _FlashcardMainCard({
    required this.topic,
    required this.word,
    required this.isBackSide,
    required this.isFavorite,
  });

  final String topic;
  final WordModel word;
  final bool isBackSide;
  final bool isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Container(
        key: ValueKey(isBackSide),
        padding: const EdgeInsets.all(AppTheme.spacing24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.cardLargeRadius,
          boxShadow: AppTheme.softShadow,
        ),
        child: isBackSide
            ? _BackSide(word: word)
            : _FrontSide(topic: topic, word: word, isFavorite: isFavorite),
      ),
    );
  }
}

class _FrontSide extends ConsumerWidget {
  const _FrontSide({
    required this.topic,
    required this.word,
    required this.isFavorite,
  });

  final String topic;
  final WordModel word;
  final bool isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: _CircleIconButton(
            icon: Icons.volume_up,
            onTap: () {
              ref.read(flashcardProvider(topic).notifier).speakCurrentWord();
            },
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: _CircleIconButton(
            icon: isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? AppTheme.primary : AppTheme.borderMedium,
            onTap: () {
              ref
                  .read(flashcardProvider(topic).notifier)
                  .toggleFavorite(word.id);
            },
          ),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word.hanzi,
                  textAlign: TextAlign.center,
                  style: AppTheme.hanziLarge.copyWith(fontSize: 88),
                ),
                const SizedBox(height: AppTheme.spacing24),
                Text(
                  word.pinyin,
                  textAlign: TextAlign.center,
                  style: AppTheme.pinyin.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackSide extends StatelessWidget {
  const _BackSide({required this.word});

  final WordModel word;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.meaningVi,
          style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacing16),
        _InfoBlock(
          title: 'Ví dụ',
          content: word.exampleZh,
          style: AppTheme.bodyBold.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppTheme.spacing12),
        _InfoBlock(
          title: 'Pinyin',
          content: word.examplePinyin,
          style: AppTheme.pinyin,
        ),
        const SizedBox(height: AppTheme.spacing12),
        _InfoBlock(
          title: 'Nghĩa',
          content: word.exampleVi,
          style: AppTheme.body,
        ),
        const Spacer(),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: [
            _Chip(text: 'HSK ${word.level}'),
            _Chip(
              text: word.category.trim().isEmpty ? 'Từ vựng' : word.category,
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.content,
    required this.style,
  });

  final String title;
  final String content;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.subtitle),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          content.trim().isEmpty ? 'Chưa có dữ liệu' : content,
          style: style,
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.color = AppTheme.primary,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.iconSoftBg,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(icon, color: color, size: 28),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.tagPadding,
      decoration: AppTheme.tagDecoration,
      child: Text(text, style: AppTheme.tag),
    );
  }
}

class _SwipeHintRow extends StatelessWidget {
  const _SwipeHintRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SwipeHintBox(
            alignment: Alignment.centerLeft,
            icon: Icons.keyboard_double_arrow_left,
            color: AppTheme.primaryLight.withOpacity(0.45),
          ),
        ),
        const SizedBox(width: AppTheme.spacing24),
        Expanded(
          child: _SwipeHintBox(
            alignment: Alignment.centerRight,
            icon: Icons.keyboard_double_arrow_right,
            color: AppTheme.success.withOpacity(0.22),
          ),
        ),
      ],
    );
  }
}

class _SwipeHintBox extends StatelessWidget {
  const _SwipeHintBox({
    required this.alignment,
    required this.icon,
    required this.color,
  });

  final Alignment alignment;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppTheme.cardLargeRadius,
      ),
      child: Icon(icon, color: Colors.white, size: 42),
    );
  }
}

class _CompleteStatRow extends StatelessWidget {
  const _CompleteStatRow({required this.label, required this.value});

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

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: AppTheme.cardPaddingAll,
        decoration: AppTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chưa có từ vựng cho chủ đề này',
              textAlign: TextAlign.center,
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              topic,
              textAlign: TextAlign.center,
              style: AppTheme.subtitleMedium,
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.flashcardTopics);
                }
              },
              child: Text('Quay lại chọn chủ đề', style: AppTheme.pinyin),
            ),
          ],
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
      child: Container(
        padding: AppTheme.cardPaddingAll,
        decoration: AppTheme.cardDecoration,
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
