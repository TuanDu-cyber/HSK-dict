import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AnswerOptionCard extends StatelessWidget {
  const AnswerOptionCard({
    super.key,
    required this.label,
    required this.text,
    this.selected = false,
    this.correct = false,
    this.wrong = false,
    this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  Color get _borderColor {
    if (correct) return AppTheme.success;
    if (wrong) return AppTheme.primary;
    if (selected) return AppTheme.primary;
    return AppTheme.borderMedium;
  }

  Color get _backgroundColor {
    if (selected || correct || wrong) return AppTheme.tagBg;
    return AppTheme.surface;
  }

  Color get _labelBackground {
    if (correct) return AppTheme.success;
    if (selected || wrong) return AppTheme.primary;
    return AppTheme.tagBg;
  }

  Color get _labelColor {
    if (selected || correct || wrong) return Colors.white;
    return AppTheme.primary;
  }

  double get _borderWidth => selected || correct || wrong ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor,
      borderRadius: AppTheme.inputRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.inputRadius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppTheme.spacing14),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: AppTheme.inputRadius,
            border: Border.all(color: _borderColor, width: _borderWidth),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _labelBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  label,
                  style: AppTheme.bodyBold.copyWith(color: _labelColor),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              Expanded(
                child: Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppTheme.spacing8),
              _StatusIcon(selected: selected, correct: correct, wrong: wrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.selected,
    required this.correct,
    required this.wrong,
  });

  final bool selected;
  final bool correct;
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    if (correct) {
      return const Icon(Icons.check_circle, color: AppTheme.success, size: 24);
    }

    if (wrong) {
      return const Icon(Icons.cancel, color: AppTheme.primary, size: 24);
    }

    if (selected) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primary, width: 2),
        ),
        child: const Center(
          child: CircleAvatar(radius: 6, backgroundColor: AppTheme.primary),
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderMedium, width: 2),
      ),
    );
  }
}
