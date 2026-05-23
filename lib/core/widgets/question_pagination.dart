import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class QuestionPagination extends StatelessWidget {
  const QuestionPagination({
    super.key,
    required this.currentIndex,
    required this.total,
    this.answeredIndexes = const {},
    this.onTapQuestion,
    this.showArrows = true,
    this.onPrevious,
    this.onNext,
  });

  final int currentIndex;
  final int total;
  final Set<int> answeredIndexes;
  final ValueChanged<int>? onTapQuestion;
  final bool showArrows;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.cardLargeRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          if (showArrows)
            _ArrowButton(icon: Icons.chevron_left, onTap: onPrevious),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(total, (index) {
                  final isCurrent = index == currentIndex;
                  final isAnswered = answeredIndexes.contains(index);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing4,
                    ),
                    child: _QuestionDot(
                      number: index + 1,
                      isCurrent: isCurrent,
                      isAnswered: isAnswered,
                      onTap: onTapQuestion == null
                          ? null
                          : () => onTapQuestion!(index),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (showArrows)
            _ArrowButton(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _QuestionDot extends StatelessWidget {
  const _QuestionDot({
    required this.number,
    required this.isCurrent,
    required this.isAnswered,
    this.onTap,
  });

  final int number;
  final bool isCurrent;
  final bool isAnswered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;

    if (isCurrent) {
      backgroundColor = AppTheme.primary;
      textColor = Colors.white;
    } else if (isAnswered) {
      backgroundColor = AppTheme.primaryLight.withOpacity(0.35);
      textColor = AppTheme.primary;
    } else {
      backgroundColor = AppTheme.iconSoftBg;
      textColor = AppTheme.textSecondary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: AppTheme.bodyBold.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          color: onTap == null ? AppTheme.textSecondary : AppTheme.primary,
        ),
      ),
    );
  }
}
