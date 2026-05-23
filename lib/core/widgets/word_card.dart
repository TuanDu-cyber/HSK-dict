import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class WordCard extends StatelessWidget {
  const WordCard({
    super.key,
    required this.hanzi,
    required this.pinyin,
    required this.meaning,
    this.tags = const [],
    this.isBookmarked = false,
    this.onTap,
    this.onSpeak,
    this.onBookmark,
  });

  final String hanzi;
  final String pinyin;
  final String meaning;
  final List<String> tags;
  final bool isBookmarked;
  final VoidCallback? onTap;
  final VoidCallback? onSpeak;
  final VoidCallback? onBookmark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.cardRadius,
        child: Container(
          padding: AppTheme.cardPaddingAll,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 76, maxWidth: 100),
                child: Text(
                  hanzi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.hanziSmall,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Expanded(
                child: _WordInfo(pinyin: pinyin, meaning: meaning, tags: tags),
              ),
              const SizedBox(width: AppTheme.spacing8),
              _IconAction(icon: Icons.volume_up_outlined, onTap: onSpeak),
              const SizedBox(width: AppTheme.spacing6),
              _IconAction(
                icon: isBookmarked
                    ? Icons.bookmark
                    : Icons.bookmark_border_outlined,
                onTap: onBookmark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordInfo extends StatelessWidget {
  const _WordInfo({
    required this.pinyin,
    required this.meaning,
    required this.tags,
  });

  final String pinyin;
  final String meaning;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pinyin,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.pinyin,
        ),
        const SizedBox(height: AppTheme.spacing2),
        Text(
          meaning,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body,
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing8),
          Wrap(
            spacing: AppTheme.spacing6,
            runSpacing: AppTheme.spacing6,
            children: tags.map((tag) => _WordTag(text: tag)).toList(),
          ),
        ],
      ],
    );
  }
}

class _WordTag extends StatelessWidget {
  const _WordTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTheme.tagPadding,
      decoration: AppTheme.tagDecoration,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.tag,
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.buttonSmallRadius,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.iconSoftBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
    );
  }
}
