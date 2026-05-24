import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/word_model.dart';
import 'quiz_provider.dart';
import 'quiz_state.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key, required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizProvider(topic));

    ref.listen<QuizState>(quizProvider(topic), (previous, next) {
      final previousVersion = previous?.completionDialogVersion ?? 0;

      if (next.completionDialogVersion > previousVersion) {
        _showCompletionDialog(context, ref, next);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: state.isLoading
            ? const _LoadingView()
            : state.error != null
            ? _ErrorView(message: state.error!)
            : state.questions.isEmpty
            ? const _EmptyQuizView()
            : _QuizContent(topic: topic, state: state),
      ),
    );
  }

  void _showCompletionDialog(
    BuildContext context,
    WidgetRef ref,
    QuizState state,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final percent = state.totalQuestions == 0
            ? 0
            : ((state.correctCount / state.totalQuestions) * 100).round();

        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
          title: Text('Hoàn thành Quiz!', style: AppTheme.headingMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bạn đã hoàn thành chủ đề ${state.topic}',
                textAlign: TextAlign.center,
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.spacing20),
              _SummaryRow(label: 'Đúng', value: '${state.correctCount} câu'),
              _SummaryRow(label: 'Sai', value: '${state.wrongCount} câu'),
              _SummaryRow(label: 'Bỏ qua', value: '${state.skippedCount} câu'),
              _SummaryRow(
                label: 'Điểm',
                value: '${state.correctCount}/${state.totalQuestions}',
              ),
              _SummaryRow(label: 'Tỉ lệ đúng', value: '$percent%'),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go(AppRoutes.quizTopics);
              },
              child: Text('Quay lại chủ đề', style: AppTheme.pinyin),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(quizProvider(topic).notifier).resetQuiz();
              },
              child: Text('Làm lại từ đầu', style: AppTheme.pinyin),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(quizProvider(topic).notifier).reviewWrongQuestions();
              },
              child: const Text('Làm lại câu sai'),
            ),
          ],
        );
      },
    );
  }
}

class _QuizContent extends ConsumerWidget {
  const _QuizContent({required this.topic, required this.state});

  final String topic;
  final QuizState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion;

    if (question == null) {
      return const _EmptyQuizView();
    }

    return Column(
      children: [
        _QuizAppBar(topic: topic),
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
                _QuizProgressCard(state: state),
                const SizedBox(height: AppTheme.spacing20),
                _QuestionCard(question: question),
                const SizedBox(height: AppTheme.spacing20),
                _AnswerList(state: state, question: question),
                const SizedBox(height: AppTheme.spacing20),
                _QuizActions(state: state),
                const SizedBox(height: AppTheme.spacing20),
                _QuizPagination(state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizAppBar extends StatelessWidget {
  const _QuizAppBar({required this.topic});

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
                  context.go(AppRoutes.quizTopics);
                }
              },
            ),
            Expanded(
              child: Center(child: Text('Quiz', style: AppTheme.headingMedium)),
            ),
            _TopIconButton(icon: Icons.bookmark_border, onTap: () {}),
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

class _QuizProgressCard extends StatelessWidget {
  const _QuizProgressCard({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context) {
    final level = _detectLevelText(state.currentQuestion?.correctWord);

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
              Expanded(child: _ProgressInfoLeft(state: state)),
              Expanded(child: _TimerCircle(seconds: state.remainingSeconds)),
              Expanded(
                child: _TopicInfo(topic: state.topic, level: level),
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
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.35),
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

  String _detectLevelText(WordModel? word) {
    if (word == null) return 'HSK';
    return 'HSK ${word.level}';
  }
}

class _ProgressInfoLeft extends StatelessWidget {
  const _ProgressInfoLeft({required this.state});

  final QuizState state;

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
                text: ' /${state.totalQuestions}',
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

class _TimerCircle extends StatelessWidget {
  const _TimerCircle({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final value = seconds / QuizNotifier.secondsPerQuestion;

    return Column(
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value.clamp(0, 1),
                strokeWidth: 8,
                backgroundColor: AppTheme.primaryLight.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
              Text(
                '00:${seconds.toString().padLeft(2, '0')}',
                style: AppTheme.bodyBold.copyWith(color: AppTheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text('Thời gian', style: AppTheme.subtitle),
      ],
    );
  }
}

class _TopicInfo extends StatelessWidget {
  const _TopicInfo({required this.topic, required this.level});

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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: 10,
            child: Opacity(
              opacity: 0.1,
              child: Text(
                '花',
                style: AppTheme.hanziLarge.copyWith(
                  fontSize: 96,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                    Icon(Icons.help_outline, color: AppTheme.primary, size: 16),
                    const SizedBox(width: AppTheme.spacing6),
                    Text('Câu hỏi', style: AppTheme.tag),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                'Chọn từ hoàn thành câu sau:',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacing20),
              Text(
                question.questionZh,
                style: AppTheme.hanziSmall.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                question.questionVi,
                style: AppTheme.body.copyWith(
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerList extends ConsumerWidget {
  const _AnswerList({required this.state, required this.question});

  final QuizState state;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: List.generate(question.options.length, (index) {
        final option = question.options[index];
        final label = String.fromCharCode(65 + index);
        final isSelected = state.isSelectedOption(option.id);
        final status = state.statusOfQuestion(state.currentIndex);

        final showResult = status != QuizAnswerStatus.none;
        final isCorrect = question.correctWordId == option.id;
        final isWrongSelected = showResult && isSelected && !isCorrect;

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == question.options.length - 1
                ? 0
                : AppTheme.spacing12,
          ),
          child: _AnswerOption(
            label: label,
            word: option,
            isSelected: isSelected,
            showResult: showResult,
            isCorrect: isCorrect,
            isWrongSelected: isWrongSelected,
            onTap: () {
              ref
                  .read(quizProvider(state.topic).notifier)
                  .selectAnswer(option.id);
            },
          ),
        );
      }),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.word,
    required this.isSelected,
    required this.showResult,
    required this.isCorrect,
    required this.isWrongSelected,
    required this.onTap,
  });

  final String label;
  final WordModel word;
  final bool isSelected;
  final bool showResult;
  final bool isCorrect;
  final bool isWrongSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = _borderColor;
    final bgColor = _backgroundColor;
    final radioColor = _radioColor;

    return Material(
      color: bgColor,
      borderRadius: AppTheme.cardRadius,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: showResult ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: AppTheme.cardRadius,
            border: Border.all(
              color: borderColor,
              width: isSelected || isCorrect ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.tagBg,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: AppTheme.bodyBold.copyWith(
                    color: AppTheme.primary,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.hanzi,
                      style: AppTheme.hanziSmall.copyWith(
                        color: AppTheme.textPrimary,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing6),
                    Wrap(
                      spacing: AppTheme.spacing20,
                      runSpacing: AppTheme.spacing4,
                      children: [
                        Text(
                          word.pinyin,
                          style: AppTheme.pinyin.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          word.meaningVi,
                          style: AppTheme.body.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: radioColor, width: 2),
                ),
                child: isSelected || (showResult && isCorrect)
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: radioColor,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _borderColor {
    if (showResult && isCorrect) return AppTheme.success;
    if (isWrongSelected) return AppTheme.primary;
    if (isSelected) return AppTheme.primary;
    return AppTheme.border;
  }

  Color get _backgroundColor {
    if (showResult && isCorrect) {
      return AppTheme.success.withOpacity(0.08);
    }

    if (isWrongSelected || isSelected) {
      return AppTheme.tagBg;
    }

    return AppTheme.surface;
  }

  Color get _radioColor {
    if (showResult && isCorrect) return AppTheme.success;
    if (isWrongSelected || isSelected) return AppTheme.primary;
    return AppTheme.borderMedium;
  }
}

class _QuizActions extends ConsumerWidget {
  const _QuizActions({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(quizProvider(state.topic).notifier);

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              onPressed: notifier.skipQuestion,
              icon: Icon(
                Icons.hide_source_outlined,
                color: AppTheme.textSecondary,
              ),
              label: Text(
                'Bỏ qua',
                style: AppTheme.bodyBold.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing16),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.buttonRadius,
                ),
              ),
              onPressed: notifier.nextQuestion,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.isLastQuestion ? 'Hoàn thành' : 'Câu tiếp theo',
                    style: AppTheme.button,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  const Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizPagination extends ConsumerWidget {
  const _QuizPagination({required this.state});

  final QuizState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(quizProvider(state.topic).notifier);

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
            onPressed: state.currentIndex > 0
                ? notifier.previousQuestion
                : null,
            icon: const Icon(Icons.chevron_left),
            color: AppTheme.textSecondary,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(state.totalQuestions, (index) {
                  final status = state.statusOfQuestion(index);
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
                }),
              ),
            ),
          ),
          IconButton(
            onPressed: state.currentIndex < state.totalQuestions - 1
                ? notifier.nextQuestion
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
  final QuizAnswerStatus status;
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
      case QuizAnswerStatus.correct:
        return AppTheme.success.withOpacity(0.15);
      case QuizAnswerStatus.wrong:
        return AppTheme.tagBg;
      case QuizAnswerStatus.skipped:
        return AppTheme.progressTrack;
      case QuizAnswerStatus.none:
        return AppTheme.tagBg.withOpacity(0.45);
    }
  }

  Color get _textColor {
    if (isCurrent) return Colors.white;

    switch (status) {
      case QuizAnswerStatus.correct:
        return AppTheme.success;
      case QuizAnswerStatus.wrong:
        return AppTheme.primary;
      case QuizAnswerStatus.skipped:
        return AppTheme.textSecondary;
      case QuizAnswerStatus.none:
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

class _EmptyQuizView extends StatelessWidget {
  const _EmptyQuizView();

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
                'Chưa đủ dữ liệu để tạo quiz cho chủ đề này.',
                textAlign: TextAlign.center,
                style: AppTheme.body,
              ),
              const SizedBox(height: AppTheme.spacing16),
              TextButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.quizTopics);
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
                    context.go(AppRoutes.quizTopics);
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
