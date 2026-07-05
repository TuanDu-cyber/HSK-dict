import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pagination_window.dart';
import '../../models/word_model.dart';
import '../../repositories/stroke_order_repository.dart';
import 'writing_provider.dart';
import 'writing_state.dart';
import 'package:stroke_order_animator/stroke_order_animator.dart';

class WritingScreen extends ConsumerWidget {
  const WritingScreen({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(writingProvider(topic));

    ref.listen<WritingState>(writingProvider(topic), (previous, next) {
      final previousVersion = previous?.completionDialogVersion ?? 0;

      if (next.completionDialogVersion > previousVersion) {
        _showCompleteDialog(context, ref, next);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: state.isLoading
            ? const _LoadingView()
            : state.error != null
            ? _ErrorView(message: state.error!)
            : state.words.isEmpty
            ? const _EmptyWritingView()
            : _WritingContent(state: state),
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    WritingState state,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final needReview = {
          ...state.wrongCharIds,
          ...state.skippedCharIds,
        }.length;

        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
          title: Text('Hoàn thành luyện viết!', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn đã hoàn thành chủ đề ${state.topic}',
                textAlign: TextAlign.center,
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.spacing20),
              _SummaryRow(
                label: 'Đã viết đúng',
                value: '${state.completedCount} ký tự',
              ),
              _SummaryRow(label: 'Cần luyện lại', value: '$needReview ký tự'),
              _SummaryRow(
                label: 'Tổng',
                value: '${state.totalCharacters} ký tự',
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(AppRoutes.writingTopics);
              },
              child: Text('Quay lại chủ đề', style: AppTheme.pinyin),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(writingProvider(topic).notifier).resetWriting();
              },
              child: Text('Làm lại từ đầu', style: AppTheme.pinyin),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(writingProvider(topic).notifier).reviewWrongWords();
              },
              child: const Text('Luyện lại chữ sai'),
            ),
          ],
        );
      },
    );
  }
}

class _WritingContent extends StatefulWidget {
  const _WritingContent({required this.state});

  final WritingState state;

  @override
  State<_WritingContent> createState() => _WritingContentState();
}

class _WritingContentState extends State<_WritingContent> {
  bool _isDrawing = false;
  bool _showUserWriting = false;
  String? _completedCharId;
  List<List<Offset>> _completedStrokes = const [];

  void _setDrawing(bool value) {
    if (_isDrawing == value) return;

    setState(() {
      _isDrawing = value;
    });
  }

  bool _hasUserWritingFor(WritingState state) {
    return _completedCharId == state.currentCharId &&
        _completedStrokes.any((stroke) => stroke.isNotEmpty);
  }

  void _showSample() {
    setState(() {
      _showUserWriting = false;
    });
  }

  void _showCompletedWriting(List<List<Offset>> strokes, String? charId) {
    setState(() {
      _completedCharId = charId;
      _completedStrokes = strokes
          .map((stroke) => List<Offset>.unmodifiable(stroke))
          .toList(growable: false);
      _showUserWriting = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final word = state.currentWord;

    if (word == null) {
      return const _EmptyWritingView();
    }

    return Column(
      children: [
        _WritingAppBar(topic: state.topic),
        Expanded(
          child: SingleChildScrollView(
            physics: _isDrawing
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              AppTheme.spacing20,
              AppTheme.screenPadding,
              AppTheme.spacing24,
            ),
            child: Column(
              children: [
                _WritingProgressCard(state: state),
                const SizedBox(height: AppTheme.spacing20),
                _WritingPracticeCard(
                  state: state,
                  word: word,
                  onDrawingChanged: _setDrawing,
                  showUserWriting:
                      _showUserWriting && _hasUserWritingFor(state),
                  hasUserWriting: _hasUserWritingFor(state),
                  userStrokes: _completedStrokes,
                  onShowSample: _showSample,
                  onWritingCompleted: (strokes) {
                    _showCompletedWriting(strokes, state.currentCharId);
                  },
                ),
                const SizedBox(height: AppTheme.spacing20),
                _WritingPagination(state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WritingAppBar extends StatelessWidget {
  const _WritingAppBar({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.screenHorizontalPadding,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            _TopIconButton(
              icon: Icons.arrow_back_ios_new,
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.writingTopics);
                }
              },
            ),
            Expanded(
              child: Center(
                child: Text('Writing', style: AppTheme.headingMedium),
              ),
            ),
            const SizedBox(width: AppTheme.appBarButtonSize),
          ],
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.appBarButtonRadius,
      child: InkWell(
        borderRadius: AppTheme.appBarButtonRadius,
        onTap: onTap,
        child: SizedBox(
          width: AppTheme.appBarButtonSize,
          height: AppTheme.appBarButtonSize,
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
      ),
    );
  }
}

class _WritingProgressCard extends StatelessWidget {
  const _WritingProgressCard({required this.state});

  final WritingState state;

  @override
  Widget build(BuildContext context) {
    final currentWord = state.currentWord;
    final level = currentWord == null ? 'HSK' : 'HSK ${currentWord.level}';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ProgressSide(state: state)),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: _TopicSide(topic: state.topic, level: level),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing20),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: state.progressValue,
                    minHeight: 8,
                    backgroundColor: AppTheme.primaryLight.withValues(
                      alpha: 0.35,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                '${state.progressPercent}%',
                style: AppTheme.bodyBold.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSide extends StatelessWidget {
  const _ProgressSide({required this.state});

  final WritingState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tiến độ', style: AppTheme.subtitleMedium),
        const SizedBox(height: AppTheme.spacing10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${state.currentQuestionNumber}',
                style: AppTheme.headingLarge,
              ),
              TextSpan(
                text: ' /${state.totalCharacters}',
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text('Ký tự', style: AppTheme.subtitle),
      ],
    );
  }
}

class _TopicSide extends StatelessWidget {
  const _TopicSide({required this.topic, required this.level});

  final String topic;
  final String level;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chủ đề', style: AppTheme.subtitleMedium),
        const SizedBox(height: AppTheme.spacing10),
        Text(
          topic,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.headingMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text('Cấp độ: $level', style: AppTheme.subtitle),
      ],
    );
  }
}

class _WritingPracticeCard extends ConsumerWidget {
  const _WritingPracticeCard({
    required this.state,
    required this.word,
    required this.onDrawingChanged,
    required this.showUserWriting,
    required this.hasUserWriting,
    required this.userStrokes,
    required this.onShowSample,
    required this.onWritingCompleted,
  });

  final WritingState state;
  final WordModel word;
  final ValueChanged<bool> onDrawingChanged;
  final bool showUserWriting;
  final bool hasUserWriting;
  final List<List<Offset>> userStrokes;
  final VoidCallback onShowSample;
  final ValueChanged<List<List<Offset>>> onWritingCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writingProvider(state.topic).notifier);
    final currentChar = state.currentCharacter ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _LevelChip(level: word.level),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      word.pinyin,
                      textAlign: TextAlign.center,
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      word.hanzi,
                      textAlign: TextAlign.center,
                      style: AppTheme.hanziSmall.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _SoundButton(onTap: notifier.speakCurrentWord),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _CharacterTabs(state: state, topic: state.topic),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Đang luyện: $currentChar',
            style: AppTheme.subtitleMedium.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _WritingMainDisplay(
            state: state,
            showUserWriting: showUserWriting,
            userStrokes: hasUserWriting ? userStrokes : const [],
          ),
          const SizedBox(height: AppTheme.spacing20),
          const _HintBox(),
          const SizedBox(height: AppTheme.spacing20),
          Row(
            children: [
              Expanded(
                child: _SoftActionButton(
                  icon: showUserWriting
                      ? Icons.visibility_outlined
                      : Icons.edit_outlined,
                  label: showUserWriting ? 'Mẫu viết' : 'Tập viết',
                  onTap: showUserWriting
                      ? onShowSample
                      : () {
                          _showWritingSheet(
                            context,
                            ref,
                            state,
                            onDrawingChanged,
                            onWritingCompleted,
                          );
                        },
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _SoftActionButton(
                  icon: Icons.refresh,
                  label: 'Viết lại',
                  onTap: () {
                    notifier.rewriteCurrent();
                    _showWritingSheet(
                      context,
                      ref,
                      state,
                      onDrawingChanged,
                      onWritingCompleted,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Bỏ qua',
                  onTap: notifier.skipCurrent,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                flex: 2,
                child: _PrimaryButton(
                  label: state.isRecognizing ? 'Đang kiểm tra...' : 'Kiểm tra',
                  onTap: state.isRecognizing
                      ? null
                      : () {
                          if (!hasUserWriting) {
                            _showFloatingWritingMessage(
                              context,
                              'Hãy bấm Tập viết và hoàn thành bài viết trước.',
                              isError: true,
                            );
                            return;
                          }

                          _showFloatingWritingMessage(
                            context,
                            'Đã ghi nhận bài viết của bạn. Hãy so sánh với mẫu để luyện đúng hơn.',
                          );
                        },
                ),
              ),
            ],
          ),
          if (state.recognizedText != null) ...[
            const SizedBox(height: AppTheme.spacing12),
            Text(
              state.recognizedText!,
              textAlign: TextAlign.center,
              style: AppTheme.subtitleMedium.copyWith(color: AppTheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showWritingSheet(
    BuildContext context,
    WidgetRef ref,
    WritingState state,
    ValueChanged<bool> onDrawingChanged,
    ValueChanged<List<List<Offset>>> onWritingCompleted,
  ) async {
    final notifier = ref.read(writingProvider(state.topic).notifier);
    final character = state.currentCharacter ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCardLarge),
        ),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final sheetState = ref.watch(writingProvider(state.topic));

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacing20,
                  AppTheme.spacing16,
                  AppTheme.spacing20,
                  AppTheme.spacing24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tập viết: $character',
                            style: AppTheme.headingMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _FreeWritingCanvas(
                      state: sheetState,
                      onDrawingChanged: onDrawingChanged,
                    ),
                    const SizedBox(height: AppTheme.spacing20),
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            label: 'Viết lại',
                            onTap: notifier.rewriteCurrent,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing12),
                        Expanded(
                          flex: 2,
                          child: _PrimaryButton(
                            label: 'Hoàn thành',
                            onTap: sheetState.strokes.isEmpty
                                ? () {
                                    _showFloatingWritingMessage(
                                      context,
                                      'Hãy viết chữ trước khi hoàn thành.',
                                      isError: true,
                                    );
                                  }
                                : () {
                                    onWritingCompleted(sheetState.strokes);
                                    Navigator.pop(sheetContext);
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    onDrawingChanged(false);
  }
}

OverlayEntry? _writingMessageOverlay;

void _showFloatingWritingMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  _writingMessageOverlay?.remove();
  _writingMessageOverlay = null;

  final top = MediaQuery.of(context).padding.top + 70;
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: top,
        left: AppTheme.spacing16,
        right: AppTheme.spacing16,
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing14,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.cardShadow,
                border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.info_outline : Icons.check_circle_outline,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacing10),
                  Expanded(
                    child: Text(
                      message,
                      style: AppTheme.bodyBold.copyWith(
                        color: isError
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  _writingMessageOverlay = entry;
  overlay.insert(entry);

  Future<void>.delayed(const Duration(seconds: 2), () {
    if (_writingMessageOverlay == entry) {
      entry.remove();
      _writingMessageOverlay = null;
    }
  });
}

class _CharacterTabs extends ConsumerWidget {
  const _CharacterTabs({required this.state, required this.topic});

  final WritingState state;
  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chars = state.currentCharacters;
    final notifier = ref.read(writingProvider(topic).notifier);

    if (chars.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.tagBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(chars.length, (index) {
            final isActive = index == state.currentCharIndex;

            return GestureDetector(
              onTap: () {
                notifier.selectCharacter(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  chars[index],
                  style: AppTheme.hanziSmall.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.tagBg,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Column(
        children: [
          const Icon(Icons.draw_outlined, color: AppTheme.primary, size: 20),
          const SizedBox(height: AppTheme.spacing6),
          Text('HSK $level', style: AppTheme.tag),
        ],
      ),
    );
  }
}

class _SoundButton extends StatelessWidget {
  const _SoundButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.tagBg,
      borderRadius: AppTheme.cardRadius,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: onTap,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: Icon(Icons.volume_up, color: AppTheme.primary, size: 30),
        ),
      ),
    );
  }
}

class _WritingMainDisplay extends StatelessWidget {
  const _WritingMainDisplay({
    required this.state,
    required this.showUserWriting,
    required this.userStrokes,
  });

  final WritingState state;
  final bool showUserWriting;
  final List<List<Offset>> userStrokes;

  @override
  Widget build(BuildContext context) {
    final currentChar = state.currentCharacter ?? '';

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            showUserWriting ? 'Bài viết của bạn' : 'Mẫu viết',
            style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimary),
          ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (showUserWriting)
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth.clamp(210.0, 340.0);

              return Center(
                child: ClipRect(
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      size: Size(size, size),
                      painter: _WritingCanvasPainter(
                        hanzi: currentChar,
                        strokes: userStrokes,
                        showAnswer: false,
                      ),
                    ),
                  ),
                ),
              );
            },
          )
        else
          _StrokeOrderAutoWriter(
            character: currentChar,
            key: ValueKey('sample_$currentChar'),
          ),
      ],
    );
  }
}

class _FreeWritingCanvas extends ConsumerWidget {
  const _FreeWritingCanvas({
    required this.state,
    required this.onDrawingChanged,
  });

  final WritingState state;
  final ValueChanged<bool> onDrawingChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writingProvider(state.topic).notifier);
    final currentChar = state.currentCharacter ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(210.0, 340.0);
        final canvasRect = Rect.fromLTWH(0, 0, size, size);

        return Center(
          child: ClipRect(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (details) {
                onDrawingChanged(true);
                final point = details.localPosition;
                if (canvasRect.contains(point)) {
                  notifier.startStroke(point);
                }
              },
              onPanUpdate: (details) {
                final point = details.localPosition;
                if (canvasRect.contains(point)) {
                  notifier.addStrokePoint(point);
                }
              },
              onPanEnd: (_) {
                notifier.endStroke();
                onDrawingChanged(false);
              },
              onPanCancel: () {
                notifier.endStroke();
                onDrawingChanged(false);
              },
              child: SizedBox(
                width: size,
                height: size,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _WritingCanvasPainter(
                    hanzi: currentChar,
                    strokes: state.strokes,
                    showAnswer: state.showAnswer,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StrokeOrderAutoWriter extends ConsumerStatefulWidget {
  const _StrokeOrderAutoWriter({super.key, required this.character});

  final String character;

  @override
  ConsumerState<_StrokeOrderAutoWriter> createState() =>
      _StrokeOrderAutoWriterState();
}

class _StrokeOrderAutoWriterState extends ConsumerState<_StrokeOrderAutoWriter>
    with TickerProviderStateMixin {
  StrokeOrderAnimationController? _controller;
  Future<StrokeOrderAnimationController>? _controllerFuture;

  @override
  void initState() {
    super.initState();
    _loadCharacter(widget.character);
  }

  @override
  void didUpdateWidget(covariant _StrokeOrderAutoWriter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.character != widget.character) {
      _controller?.dispose();
      _controller = null;
      _loadCharacter(widget.character);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _loadCharacter(String character) {
    if (character.trim().isEmpty) return;

    setState(() {
      _controllerFuture = _createController(character);
    });
  }

  Future<StrokeOrderAnimationController> _createController(
    String character,
  ) async {
    final rawData = await ref
        .read(strokeOrderRepositoryProvider)
        .loadStrokeOrder(character);

    final controller = StrokeOrderAnimationController(
      StrokeOrder(rawData),
      this,
    );

    controller.setShowOutline(true);
    controller.setShowBackground(true);
    controller.setShowMedian(false);

    _controller = controller;

    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final future = _controllerFuture;

    if (future == null) {
      return _StrokeOrderFallback(
        message: 'Chưa có chữ để hiển thị nét mẫu.',
        character: widget.character,
      );
    }

    return FutureBuilder<StrokeOrderAnimationController>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _StrokeOrderLoading(character: widget.character);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _StrokeOrderFallback(
            message: 'Chưa tải được nét mẫu cho chữ ${widget.character}.',
            character: widget.character,
          );
        }

        final controller = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            final sizeValue = constraints.maxWidth.clamp(210.0, 340.0);
            final size = Size(sizeValue, sizeValue);

            return Column(
              children: [
                Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.45),
                    ),
                  ),
                  child: StrokeOrderAnimator(
                    controller,
                    size: size,
                    key: ValueKey('animator_${widget.character}'),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                _StrokeOrderControls(controller: controller),
              ],
            );
          },
        );
      },
    );
  }
}

class _StrokeOrderLoading extends StatelessWidget {
  const _StrokeOrderLoading({required this.character});

  final String character;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(210.0, 340.0);

        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Đang tải nét mẫu cho chữ $character...',
                textAlign: TextAlign.center,
                style: AppTheme.subtitleMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StrokeOrderFallback extends StatelessWidget {
  const _StrokeOrderFallback({required this.message, required this.character});

  final String message;
  final String character;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(210.0, 340.0);

        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                character,
                style: AppTheme.hanziLarge.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.35),
                  fontSize: size * 0.55,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing20,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTheme.subtitleMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StrokeOrderControls extends StatelessWidget {
  const _StrokeOrderControls({required this.controller});

  final StrokeOrderAnimationController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: [
            _StrokeControlButton(
              icon: controller.isAnimating
                  ? Icons.stop_circle_outlined
                  : Icons.play_arrow_rounded,
              label: controller.isAnimating ? 'Dừng' : 'Chạy nét mẫu',
              onTap: controller.isAnimating
                  ? controller.stopAnimation
                  : controller.startAnimation,
            ),
            _StrokeControlButton(
              icon: Icons.navigate_next,
              label: 'Nét tiếp',
              onTap: controller.isAnimating ? null : controller.nextStroke,
            ),
            _StrokeControlButton(
              icon: Icons.visibility,
              label: 'Hiện đầy đủ',
              onTap: controller.showFullCharacter,
            ),
            _StrokeControlButton(
              icon: Icons.restart_alt,
              label: 'Làm lại',
              onTap: controller.reset,
            ),
          ],
        );
      },
    );
  }
}

class _StrokeControlButton extends StatelessWidget {
  const _StrokeControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.tagBg,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.buttonSmallRadius,
          ),
        ),
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 17,
          color: onTap == null ? AppTheme.textSecondary : AppTheme.primary,
        ),
        label: Text(
          label,
          style: AppTheme.tag.copyWith(
            color: onTap == null ? AppTheme.textSecondary : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _WritingCanvasPainter extends CustomPainter {
  const _WritingCanvasPainter({
    required this.hanzi,
    required this.strokes,
    required this.showAnswer,
  });

  final String hanzi;
  final List<List<Offset>> strokes;
  final bool showAnswer;

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final guidePaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final userPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.save();
    canvas.clipRect(rect);

    canvas.drawRect(rect, borderPaint);

    _drawDashedLine(
      canvas,
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset.zero,
      Offset(size.width, size.height),
      guidePaint,
    );
    _drawDashedLine(
      canvas,
      Offset(size.width, 0),
      Offset(0, size.height),
      guidePaint,
    );

    final samplePainter = TextPainter(
      text: TextSpan(
        text: hanzi,
        style: TextStyle(
          fontSize: size.width * 0.62,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary.withValues(
            alpha: showAnswer ? 0.36 : 0.16,
          ),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    samplePainter.paint(
      canvas,
      Offset(
        (size.width - samplePainter.width) / 2,
        (size.height - samplePainter.height) / 2,
      ),
    );

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);

      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, userPaint);
    }

    canvas.restore();
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 7.0;

    final distance = (end - start).distance;

    if (distance == 0) return;

    final direction = (end - start) / distance;

    double currentDistance = 0;

    while (currentDistance < distance) {
      final from = start + direction * currentDistance;
      final double nextDistance = (currentDistance + dashWidth)
          .clamp(0.0, distance)
          .toDouble();

      final to = start + direction * nextDistance;
      canvas.drawLine(from, to, paint);

      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _WritingCanvasPainter oldDelegate) {
    return oldDelegate.hanzi != hanzi ||
        oldDelegate.strokes != strokes ||
        oldDelegate.showAnswer != showAnswer;
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡 Gợi ý viết',
            style: AppTheme.bodyBold.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Quan sát chữ mẫu và viết theo đúng thứ tự nét. Với từ nhiều chữ, hãy chọn từng chữ để luyện viết riêng.',
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

class _SoftActionButton extends StatelessWidget {
  const _SoftActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: AppTheme.textPrimary, size: 18),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTheme.bodyBold.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.buttonRadius,
            side: BorderSide(
              color: AppTheme.primaryLight.withValues(alpha: 0.45),
            ),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: AppTheme.bodyBold.copyWith(color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: onTap,
        child: Text(label, style: AppTheme.button),
      ),
    );
  }
}

class _WritingPagination extends ConsumerWidget {
  const _WritingPagination({required this.state});

  final WritingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(writingProvider(state.topic).notifier);
    final window = buildPaginationWindow(
      currentIndex: state.currentIndex,
      total: state.totalWords,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: AppTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: window.canGoPreviousGroup
                ? () => notifier.goToWord(window.startIndex - 5)
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppTheme.textSecondary,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: window.indexes.map((index) {
                  final status = state.statusOfWord(index);
                  final isCurrent = index == state.currentIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing4,
                    ),
                    child: _PaginationNumber(
                      number: index + 1,
                      isCurrent: isCurrent,
                      status: status,
                      onTap: () {
                        notifier.goToWord(index);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            onPressed: window.canGoNextGroup
                ? () => notifier.goToWord(window.endIndex + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _PaginationNumber extends StatelessWidget {
  const _PaginationNumber({
    required this.number,
    required this.isCurrent,
    required this.status,
    required this.onTap,
  });

  final int number;
  final bool isCurrent;
  final WritingWordStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColor;
    final textColor = _textColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Text(
          '$number',
          style: AppTheme.bodyBold.copyWith(color: textColor),
        ),
      ),
    );
  }

  Color get _backgroundColor {
    if (isCurrent) return AppTheme.primary;

    switch (status) {
      case WritingWordStatus.completed:
        return AppTheme.success.withValues(alpha: 0.15);
      case WritingWordStatus.wrong:
        return AppTheme.tagBg;
      case WritingWordStatus.skipped:
        return AppTheme.progressTrack;
      case WritingWordStatus.none:
        return AppTheme.tagBg.withValues(alpha: 0.45);
    }
  }

  Color get _textColor {
    if (isCurrent) return Colors.white;

    switch (status) {
      case WritingWordStatus.completed:
        return AppTheme.success;
      case WritingWordStatus.wrong:
        return AppTheme.primary;
      case WritingWordStatus.skipped:
        return AppTheme.textSecondary;
      case WritingWordStatus.none:
        return AppTheme.textPrimary;
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTheme.subtitleMedium)),
          Text(value, style: AppTheme.bodyBold),
        ],
      ),
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

class _EmptyWritingView extends StatelessWidget {
  const _EmptyWritingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPaddingAll,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardLargeRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chưa có ký tự cho chủ đề này.',
                textAlign: TextAlign.center,
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.writingTopics);
                  }
                },
                child: Text('Quay lại chọn chủ đề', style: AppTheme.pinyin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppTheme.screenPaddingAll,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardLargeRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center, style: AppTheme.body),
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.writingTopics);
                  }
                },
                child: Text('Quay lại chọn chủ đề', style: AppTheme.pinyin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
