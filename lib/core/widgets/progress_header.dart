import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.current,
    required this.total,
    required this.topic,
    required this.progressValue,
    this.subtitle,
    this.centerText,
    this.centerIcon,
    this.centerValue,
  });

  final int current;
  final int total;
  final String topic;
  final double progressValue;
  final String? subtitle;
  final String? centerText;
  final IconData? centerIcon;
  final double? centerValue;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progressValue.clamp(0.0, 1.0);

    return Container(
      padding: AppTheme.cardPaddingAll,
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ProgressInfo(current: current, total: total),
              ),
              Expanded(
                child: _CenterProgress(
                  value: centerValue ?? safeProgress,
                  text: centerText,
                  icon: centerIcon,
                ),
              ),
              Expanded(
                child: _TopicInfo(topic: topic, subtitle: subtitle),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: safeProgress,
              minHeight: 6,
              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.45),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressInfo extends StatelessWidget {
  const _ProgressInfo({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tiến độ', style: AppTheme.subtitle),
        const SizedBox(height: AppTheme.spacing6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: '$current', style: AppTheme.progressNumber),
                TextSpan(
                  text: ' / $total',
                  style: AppTheme.progressNumber.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text('Câu hỏi', style: AppTheme.subtitle),
      ],
    );
  }
}

class _CenterProgress extends StatelessWidget {
  const _CenterProgress({required this.value, this.text, this.icon});

  final double value;
  final String? text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: safeValue,
                strokeWidth: 6,
                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.35),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
              if (icon != null)
                Icon(icon, color: AppTheme.primary, size: 28)
              else
                Text(
                  text ?? '${(safeValue * 100).round()}%',
                  style: AppTheme.tag.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        if (text != null && icon != null) ...[
          const SizedBox(height: AppTheme.spacing6),
          Text(
            text!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.subtitle,
          ),
        ],
      ],
    );
  }
}

class _TopicInfo extends StatelessWidget {
  const _TopicInfo({required this.topic, this.subtitle});

  final String topic;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chủ đề', style: AppTheme.subtitle),
        const SizedBox(height: AppTheme.spacing6),
        Text(
          topic,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.headingMedium,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.subtitleMedium,
          ),
        ],
      ],
    );
  }
}
