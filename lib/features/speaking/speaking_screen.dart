import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pagination_window.dart';
import '../../models/word_model.dart';
import 'speaking_provider.dart';
import 'speaking_state.dart';

class SpeakingScreen extends ConsumerWidget {
  const SpeakingScreen({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(speakingProvider(topic));

    ref.listen<SpeakingState>(speakingProvider(topic), (previous, next) {
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
            ? const _EmptySpeakingView()
            : _SpeakingContent(state: state),
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    WidgetRef ref,
    SpeakingState state,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final needReview = {
          ...state.lowScoreWordIds,
          ...state.skippedWordIds,
        }.length;

        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
          title: Text('Hoàn thành luyện nói!', style: AppTheme.headingMedium),
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
                label: 'Điểm trung bình',
                value: '${state.averageScore}%',
              ),
              _SummaryRow(
                label: 'Phát âm tốt',
                value: '${state.completedCount} câu',
              ),
              _SummaryRow(label: 'Cần luyện lại', value: '$needReview câu'),
              _SummaryRow(label: 'Tổng', value: '${state.totalWords} câu'),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(AppRoutes.speakingTopics);
              },
              child: Text('Quay lại chủ đề', style: AppTheme.pinyin),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(speakingProvider(topic).notifier).resetSpeaking();
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
                ref
                    .read(speakingProvider(topic).notifier)
                    .reviewLowScoreWords();
              },
              child: const Text('Luyện lại câu chưa tốt'),
            ),
          ],
        );
      },
    );
  }
}

class _SpeakingContent extends StatelessWidget {
  const _SpeakingContent({required this.state});

  final SpeakingState state;

  @override
  Widget build(BuildContext context) {
    final word = state.currentWord;

    if (word == null) {
      return const _EmptySpeakingView();
    }

    return Column(
      children: [
        _SpeakingAppBar(topic: state.topic),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPadding,
              AppTheme.spacing20,
              AppTheme.screenPadding,
              AppTheme.spacing24,
            ),
            child: Column(
              children: [
                _SpeakingProgressCard(state: state),
                const SizedBox(height: AppTheme.spacing20),
                _SpeakingPracticeCard(state: state, word: word),
                const SizedBox(height: AppTheme.spacing20),
                _SpeakingPagination(state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeakingAppBar extends StatelessWidget {
  const _SpeakingAppBar({required this.topic});

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
                  context.go(AppRoutes.speakingTopics);
                }
              },
            ),
            Expanded(
              child: Center(
                child: Text('Speaking', style: AppTheme.headingMedium),
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

class _SpeakingProgressCard extends StatelessWidget {
  const _SpeakingProgressCard({required this.state});

  final SpeakingState state;

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
              Expanded(
                child: _MicProgressCircle(percent: state.progressPercent),
              ),
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

  final SpeakingState state;

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
                text: ' /${state.totalWords}',
                style: AppTheme.headingLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text('Câu hỏi', style: AppTheme.subtitle),
      ],
    );
  }
}

class _MicProgressCircle extends StatelessWidget {
  const _MicProgressCircle({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 8,
                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
              const Icon(Icons.mic, color: AppTheme.primary, size: 34),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          '$percent%',
          style: AppTheme.bodyBold.copyWith(color: AppTheme.primary),
        ),
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
        Text(level, style: AppTheme.subtitle),
      ],
    );
  }
}

class _SpeakingPracticeCard extends ConsumerWidget {
  const _SpeakingPracticeCard({required this.state, required this.word});

  final SpeakingState state;
  final WordModel word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(speakingProvider(state.topic).notifier);

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
          _PronunciationCard(word: word, onSpeak: notifier.speakCurrentWord),
          const SizedBox(height: AppTheme.spacing20),
          _RecordingPanel(state: state, onMicTap: notifier.toggleRecording),
          if (state.hasResultForCurrentWord) ...[
            const SizedBox(height: AppTheme.spacing20),
            _ResultCard(state: state),
          ],
          const SizedBox(height: AppTheme.spacing20),
          _ActionButtons(state: state),
        ],
      ),
    );
  }
}

class _PronunciationCard extends StatelessWidget {
  const _PronunciationCard({required this.word, required this.onSpeak});

  final WordModel word;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: -10,
          top: 30,
          child: Opacity(
            opacity: 0.18,
            child: Text(
              '花',
              style: AppTheme.hanziLarge.copyWith(
                fontSize: 52,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.tagBg,
                  borderRadius: AppTheme.tagRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: AppTheme.primary, size: 17),
                    const SizedBox(width: AppTheme.spacing6),
                    Text('Phát âm', style: AppTheme.tag),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: _SmallSoundButton(onTap: onSpeak),
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              word.hanzi,
              textAlign: TextAlign.center,
              style: AppTheme.hanziLarge.copyWith(
                fontSize: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing10),
            Text(
              word.pinyin,
              textAlign: TextAlign.center,
              style: AppTheme.headingLarge.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Container(
              width: 70,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SmallSoundButton extends StatelessWidget {
  const _SmallSoundButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.cardRadius,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.tagBg,
            borderRadius: AppTheme.cardRadius,
          ),
          child: const Icon(Icons.volume_up, color: AppTheme.primary),
        ),
      ),
    );
  }
}

class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({required this.state, required this.onMicTap});

  final SpeakingState state;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    final seconds = state.recordDuration.inMilliseconds / 1000;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.65),
        borderRadius: AppTheme.cardLargeRadius,
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        children: [
          Text(
            state.isRecording ? 'Đang ghi âm...' : 'Nhấn để ghi âm',
            style: AppTheme.bodyBold.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacing14),
          _RecordButton(isRecording: state.isRecording, onTap: onMicTap),
          const SizedBox(height: AppTheme.spacing10),
          Text(
            '00:${seconds.toStringAsFixed(1).padLeft(4, '0')}',
            style: AppTheme.bodyBold.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _FakeWaveform(isRecording: state.isRecording),
          if (state.recognizedText != null &&
              state.recognizedText!.trim().isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'Nhận diện: ${state.recognizedText}',
              textAlign: TextAlign.center,
              style: AppTheme.subtitleMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({required this.isRecording, required this.onTap});

  final bool isRecording;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: isRecording ? 1.08 : 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: AppTheme.primary,
            shape: const CircleBorder(),
            elevation: isRecording ? 8 : 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 88,
                height: 88,
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FakeWaveform extends StatelessWidget {
  const _FakeWaveform({required this.isRecording});

  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barCount = (constraints.maxWidth / 10).floor().clamp(18, 34);

        return SizedBox(
          width: double.infinity,
          height: 46,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(barCount, (index) {
              final base = 8 + (index % 5) * 3;
              final extra = isRecording ? Random(index).nextInt(14) : 0;
              final height = (base + extra).toDouble();

              return Flexible(
                child: Container(
                  width: 3,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.state});

  final SpeakingState state;

  @override
  Widget build(BuildContext context) {
    final score = state.currentScore;
    final isGood = score >= 80;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Kết quả phát âm', style: AppTheme.bodyBold),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Text(
                '$score%',
                style: AppTheme.headingLarge.copyWith(
                  color: isGood ? AppTheme.success : AppTheme.primary,
                  fontSize: 32,
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing8,
                ),
                decoration: BoxDecoration(
                  color: isGood
                      ? AppTheme.success.withValues(alpha: 0.14)
                      : AppTheme.tagBg,
                  borderRadius: AppTheme.tagRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      isGood ? Icons.star : Icons.refresh,
                      color: isGood ? AppTheme.success : AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppTheme.spacing6),
                    Text(
                      isGood ? 'Phát âm tốt' : 'Cần luyện thêm',
                      style: AppTheme.bodyBold.copyWith(
                        color: isGood ? AppTheme.success : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            state.currentFeedback,
            style: AppTheme.body.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 360;

              if (isSmall) {
                return Column(
                  children: [
                    _ScoreMetric(
                      label: 'Âm đầu',
                      score: state.currentInitialScore,
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _ScoreMetric(label: 'Vần', score: state.currentFinalScore),
                    const SizedBox(height: AppTheme.spacing12),
                    _ScoreMetric(
                      label: 'Thanh điệu',
                      score: state.currentToneScore,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _ScoreMetric(
                      label: 'Âm đầu',
                      score: state.currentInitialScore,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: _ScoreMetric(
                      label: 'Vần',
                      score: state.currentFinalScore,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: _ScoreMetric(
                      label: 'Thanh điệu',
                      score: state.currentToneScore,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScoreMetric extends StatelessWidget {
  const _ScoreMetric({required this.label, required this.score});

  final String label;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTheme.bodyBold),
        const SizedBox(height: AppTheme.spacing8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.28),
            valueColor: AlwaysStoppedAnimation<Color>(
              score >= 80 ? AppTheme.success : AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing6),
        Text('$score%', style: AppTheme.subtitle),
      ],
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.state});

  final SpeakingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(speakingProvider(state.topic).notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 380;

        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _SoftActionButton(
                      icon: Icons.volume_up,
                      label: 'Nghe lại',
                      onTap: notifier.replayRecording,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: _SoftActionButton(
                      icon: Icons.refresh,
                      label: 'Ghi lại',
                      onTap: notifier.recordAgain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing12),
              SizedBox(
                width: double.infinity,
                child: _PrimaryActionButton(
                  label: state.isLastQuestion ? 'Hoàn thành' : 'Tiếp tục',
                  onTap: notifier.nextQuestion,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _SoftActionButton(
                icon: Icons.volume_up,
                label: 'Nghe lại',
                onTap: notifier.replayRecording,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _SoftActionButton(
                icon: Icons.refresh,
                label: 'Ghi lại',
                onTap: notifier.recordAgain,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: _PrimaryActionButton(
                label: state.isLastQuestion ? 'Hoàn thành' : 'Tiếp tục',
                onTap: notifier.nextQuestion,
              ),
            ),
          ],
        );
      },
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
      height: 54,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.background,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: AppTheme.textPrimary, size: 20),
        label: Text(
          label,
          style: AppTheme.bodyBold.copyWith(
            color: AppTheme.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTheme.button.copyWith(fontSize: 13)),
            const SizedBox(width: AppTheme.spacing6),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SpeakingPagination extends ConsumerWidget {
  const _SpeakingPagination({required this.state});

  final SpeakingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(speakingProvider(state.topic).notifier);
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
                ? () => notifier.goToQuestion(window.startIndex - 5)
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
                        notifier.goToQuestion(index);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          IconButton(
            onPressed: window.canGoNextGroup
                ? () => notifier.goToQuestion(window.endIndex + 1)
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
  final SpeakingWordStatus status;
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
      case SpeakingWordStatus.completed:
        return AppTheme.success.withValues(alpha: 0.15);
      case SpeakingWordStatus.lowScore:
        return AppTheme.tagBg;
      case SpeakingWordStatus.skipped:
        return AppTheme.progressTrack;
      case SpeakingWordStatus.none:
        return AppTheme.tagBg.withValues(alpha: 0.45);
    }
  }

  Color get _textColor {
    if (isCurrent) return Colors.white;

    switch (status) {
      case SpeakingWordStatus.completed:
        return AppTheme.success;
      case SpeakingWordStatus.lowScore:
        return AppTheme.primary;
      case SpeakingWordStatus.skipped:
        return AppTheme.textSecondary;
      case SpeakingWordStatus.none:
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

class _EmptySpeakingView extends StatelessWidget {
  const _EmptySpeakingView();

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
                'Chưa có dữ liệu luyện nói cho chủ đề này.',
                textAlign: TextAlign.center,
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.speakingTopics);
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
                    context.go(AppRoutes.speakingTopics);
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
