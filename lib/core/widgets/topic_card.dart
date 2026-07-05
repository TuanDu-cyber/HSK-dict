import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    required this.progressValue,
    this.showProgress = true,
    this.progressText,
    this.compact = false,
    this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final double progressValue;
  final String? progressText;
  final bool compact;
  final VoidCallback? onTap;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final safeProgress = progressValue.clamp(0.0, 1.0);

    final double padding = compact ? 10 : AppTheme.cardPadding;
    final double iconSize = compact ? 46 : 56;
    final double iconDataSize = compact ? 24 : 28;
    final double titleFontSize = compact ? 13.5 : 15;
    final double subtitleFontSize = compact ? 11 : 12;
    final double arrowSize = compact ? 30 : 36;

    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.topicCardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.topicCardRadius,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.topicCardRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopicIndex(index: index),
              SizedBox(
                height: compact ? AppTheme.spacing8 : AppTheme.spacing12,
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: iconDataSize,
                      ),
                    ),
                    SizedBox(
                      width: compact ? AppTheme.spacing8 : AppTheme.spacing12,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: compact ? 2 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.bodyBold.copyWith(
                              fontSize: titleFontSize,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacing4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.subtitle.copyWith(
                              fontSize: subtitleFontSize,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: compact ? AppTheme.spacing4 : AppTheme.spacing8,
                    ),
                    Container(
                      width: arrowSize,
                      height: arrowSize,
                      decoration: BoxDecoration(
                        color: AppTheme.iconSoftBg,
                        borderRadius: BorderRadius.circular(arrowSize / 2),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: AppTheme.primary,
                        size: compact ? 20 : 24,
                      ),
                    ),
                  ],
                ),
              ),
              if (showProgress) ...[
                SizedBox(
                  height: compact ? AppTheme.spacing8 : AppTheme.spacing10,
                ),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: safeProgress,
                          minHeight: 5,
                          backgroundColor: AppTheme.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      progressText ?? '${(safeProgress * 100).round()}%',
                      style: AppTheme.subtitle.copyWith(
                        fontSize: compact ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicIndex extends StatelessWidget {
  const _TopicIndex({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: AppTheme.spacing4,
      ),
      decoration: AppTheme.tagDecoration,
      child: Text(
        index.toString().padLeft(2, '0'),
        style: AppTheme.tag.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
