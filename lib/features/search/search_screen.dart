import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_decorative_background.dart';
import '../../core/widgets/bottom_nav.dart';
import '../../models/word_model.dart';
import 'search_provider.dart';
import 'search_state.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    ref.listen<SearchState>(searchProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppTheme.primary,
          ),
        );
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
                  : const _SearchBody(),
            ),
            BottomNav(
              currentIndex: 1,
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
}

class _SearchBody extends ConsumerWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.screenPadding,
        AppTheme.spacing24,
        AppTheme.screenPadding,
        140,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SearchHeader(),
          const SizedBox(height: AppTheme.spacing28),
          const _SearchBarSection(),
          const SizedBox(height: AppTheme.spacing28),
          _RecentSearchSection(state: state),
          const SizedBox(height: AppTheme.spacing28),
          _SearchResultSection(state: state),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tìm kiếm',
          style: AppTheme.headingXLarge.copyWith(
            color: AppTheme.primary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTheme.spacing10),
        Text(
          'Tìm từ vựng, pinyin hoặc nghĩa tiếng Việt',
          style: AppTheme.body.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 17,
          ),
        ),
      ],
    );
  }
}

class _SearchBarSection extends ConsumerStatefulWidget {
  const _SearchBarSection();

  @override
  ConsumerState<_SearchBarSection> createState() => _SearchBarSectionState();
}

class _SearchBarSectionState extends ConsumerState<_SearchBarSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: ref.read(searchProvider).query);
  }

  @override
  void didUpdateWidget(covariant _SearchBarSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final query = ref.read(searchProvider).query;

    if (_controller.text != query) {
      _controller.text = query;
      _controller.selection = TextSelection.collapsed(offset: query.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.cardLargeRadius,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                const SizedBox(width: AppTheme.spacing20),
                const Icon(Icons.search, color: AppTheme.primary, size: 32),
                const SizedBox(width: AppTheme.spacing16),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTheme.bodyBold.copyWith(
                      fontSize: 20,
                      color: AppTheme.textPrimary,
                    ),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Nhập từ cần tìm...',
                      hintStyle: AppTheme.body.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 17,
                      ),
                    ),
                    onChanged: notifier.updateQuery,
                    onSubmitted: (_) {
                      notifier.submitSearch();
                    },
                  ),
                ),
                if (state.query.trim().isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _controller.clear();
                      notifier.clearQuery();
                    },
                    icon: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppTheme.border,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 17,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                const SizedBox(width: AppTheme.spacing8),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing14),
        _FilterButton(
          isActive: state.hasActiveFilter,
          onTap: () {
            _showFilterSheet(context, ref);
          },
        ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCardLarge),
        ),
      ),
      builder: (context) {
        return const _FilterSheet();
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.cardLargeRadius,
      child: InkWell(
        borderRadius: AppTheme.cardLargeRadius,
        onTap: onTap,
        child: Container(
          width: 76,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: AppTheme.cardLargeRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.filter_list,
                color: isActive ? AppTheme.primaryDark : AppTheme.primary,
                size: 30,
              ),
              const SizedBox(height: AppTheme.spacing4),
              Text(
                'Lọc',
                style: AppTheme.tag.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentSearchSection extends ConsumerWidget {
  const _RecentSearchSection({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = state.recentSearches;

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(searchProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.history, title: 'Tìm kiếm gần đây'),
        const SizedBox(height: AppTheme.spacing16),
        Wrap(
          spacing: AppTheme.spacing12,
          runSpacing: AppTheme.spacing12,
          children: history.map((query) {
            return _RecentChip(
              label: query,
              onTap: () {
                notifier.search(query);
              },
              onRemove: () {
                notifier.removeRecentSearch(query);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.buttonSmallRadius,
      child: InkWell(
        borderRadius: AppTheme.buttonSmallRadius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing10,
          ),
          decoration: BoxDecoration(
            borderRadius: AppTheme.buttonSmallRadius,
            border: Border.all(
              color: AppTheme.borderMedium.withValues(alpha: 0.65),
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasQuery && !state.hasActiveFilter) {
      return const _SearchSuggestionCard();
    }

    if (state.results.isEmpty) {
      return const _EmptyResultCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.assignment_outlined,
          title: 'Kết quả tìm kiếm',
          trailing: '${state.results.length} kết quả',
        ),
        const SizedBox(height: AppTheme.spacing16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.results.length,
          separatorBuilder: (_, _) {
            return const SizedBox(height: AppTheme.spacing12);
          },
          itemBuilder: (context, index) {
            final word = state.results[index];

            return _SearchWordCard(word: word);
          },
        ),
      ],
    );
  }
}

class _SearchWordCard extends ConsumerWidget {
  const _SearchWordCard({required this.word});

  final WordModel word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final isFavorite = state.favoriteWordIds.contains(word.id);

    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.cardLargeRadius,
      child: InkWell(
        borderRadius: AppTheme.cardLargeRadius,
        onTap: () {
          _showWordDetailSheet(context, ref, word);
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.cardLargeRadius,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 108,
                child: Text(
                  word.hanzi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.hanziMedium.copyWith(
                    color: AppTheme.primary,
                    fontSize: word.hanzi.length > 2 ? 28 : 32,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing10),
              Expanded(child: _WordInfo(word: word)),
              const SizedBox(width: AppTheme.spacing8),
              Column(
                children: [
                  _CircleIconButton(
                    icon: Icons.volume_up,
                    filled: true,
                    onTap: () {
                      notifier.speakWord(word);
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing12),
                  _CircleIconButton(
                    icon: isFavorite ? Icons.bookmark : Icons.bookmark_border,
                    filled: false,
                    onTap: () {
                      notifier.toggleFavorite(word.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWordDetailSheet(
    BuildContext context,
    WidgetRef ref,
    WordModel word,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusCardLarge),
        ),
      ),
      builder: (context) {
        return _WordDetailSheet(word: word);
      },
    );
  }
}

class _WordInfo extends StatelessWidget {
  const _WordInfo({required this.word});

  final WordModel word;

  @override
  Widget build(BuildContext context) {
    final shouldShowExample = word.exampleZh.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          word.pinyin,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyBold.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          word.meaningVi,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.body.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppTheme.spacing10),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing6,
          children: [
            _SmallTag(label: 'HSK ${word.level}'),
            _SmallTag(
              label: word.category.trim().isEmpty ? word.topic : word.category,
              icon: Icons.local_cafe_outlined,
            ),
          ],
        ),
        if (shouldShowExample) ...[
          const SizedBox(height: AppTheme.spacing12),
          Text(
            word.exampleZh,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.body.copyWith(
              color: AppTheme.primary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppTheme.spacing2),
          Text(
            word.exampleVi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.subtitle.copyWith(fontSize: 14),
          ),
        ],
      ],
    );
  }
}

class _SmallTag extends StatelessWidget {
  const _SmallTag({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing10,
        vertical: AppTheme.spacing6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.tagBg,
        borderRadius: AppTheme.tagRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppTheme.primary),
            const SizedBox(width: AppTheme.spacing4),
          ],
          Text(
            label,
            style: AppTheme.tag.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.filled,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppTheme.iconSoftBg : Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: AppTheme.primary, size: 25),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(width: AppTheme.spacing10),
        Expanded(
          child: Text(
            title,
            style: AppTheme.headingMedium.copyWith(fontSize: 19),
          ),
        ),
        if (trailing != null) Text(trailing!, style: AppTheme.subtitleMedium),
      ],
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing20,
        right: AppTheme.spacing20,
        top: AppTheme.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text('Bộ lọc', style: AppTheme.headingMedium)),
            const SizedBox(height: AppTheme.spacing24),
            Text('Cấp độ', style: AppTheme.bodyBold),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing10,
              runSpacing: AppTheme.spacing10,
              children: [
                _FilterChipItem(
                  label: 'Tất cả',
                  isSelected: state.selectedLevel == null && !state.onlySaved,
                  onTap: () {
                    notifier.applyLevelFilter(null);
                    notifier.setOnlySaved(false);
                  },
                ),
                _FilterChipItem(
                  label: 'HSK 1',
                  isSelected: state.selectedLevel == 1,
                  onTap: () => notifier.applyLevelFilter(1),
                ),
                _FilterChipItem(
                  label: 'HSK 2',
                  isSelected: state.selectedLevel == 2,
                  onTap: () => notifier.applyLevelFilter(2),
                ),
                _FilterChipItem(
                  label: 'Đã lưu',
                  isSelected: state.onlySaved,
                  onTap: notifier.toggleOnlySaved,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),
            Text('Chủ đề', style: AppTheme.bodyBold),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing10,
              runSpacing: AppTheme.spacing10,
              children: [
                _FilterChipItem(
                  label: 'Tất cả chủ đề',
                  isSelected: state.selectedTopic == null,
                  onTap: () => notifier.applyTopicFilter(null),
                ),
                ...state.availableTopics.map((topic) {
                  return _FilterChipItem(
                    label: topic,
                    isSelected: state.selectedTopic == topic,
                    onTap: () => notifier.applyTopicFilter(topic),
                  );
                }),
              ],
            ),
            const SizedBox(height: AppTheme.spacing28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.buttonRadius,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing14,
                      ),
                    ),
                    onPressed: () {
                      notifier.clearFilters();
                    },
                    child: Text(
                      'Xóa lọc',
                      style: AppTheme.bodyBold.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.buttonRadius,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing14,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Áp dụng', style: AppTheme.button),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.tagBg,
      labelStyle: AppTheme.bodyMedium.copyWith(
        color: isSelected ? Colors.white : AppTheme.primary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.buttonSmallRadius,
        side: BorderSide(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
    );
  }
}

class _WordDetailSheet extends ConsumerWidget {
  const _WordDetailSheet({required this.word});

  final WordModel word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);
    final isFavorite = state.favoriteWordIds.contains(word.id);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacing24,
        AppTheme.spacing24,
        AppTheme.spacing24,
        AppTheme.spacing32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.hanzi,
              textAlign: TextAlign.center,
              style: AppTheme.hanziLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(word.pinyin, style: AppTheme.headingMedium),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              word.meaningVi,
              textAlign: TextAlign.center,
              style: AppTheme.bodyBold.copyWith(fontSize: 20),
            ),
            const SizedBox(height: AppTheme.spacing20),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              alignment: WrapAlignment.center,
              children: [
                _SmallTag(label: 'HSK ${word.level}'),
                _SmallTag(label: word.topic),
                _SmallTag(label: word.category),
              ],
            ),
            const SizedBox(height: AppTheme.spacing24),
            _DetailInfoBlock(title: 'Ví dụ', content: word.exampleZh),
            _DetailInfoBlock(title: 'Pinyin', content: word.examplePinyin),
            _DetailInfoBlock(title: 'Dịch nghĩa', content: word.exampleVi),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.buttonRadius,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacing14,
                      ),
                    ),
                    onPressed: () {
                      notifier.speakWord(word);
                    },
                    icon: const Icon(Icons.volume_up),
                    label: Text('Nghe phát âm', style: AppTheme.button),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Material(
                  color: AppTheme.tagBg,
                  borderRadius: AppTheme.buttonRadius,
                  child: InkWell(
                    borderRadius: AppTheme.buttonRadius,
                    onTap: () {
                      notifier.toggleFavorite(word.id);
                    },
                    child: SizedBox(
                      width: 58,
                      height: 52,
                      child: Icon(
                        isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailInfoBlock extends StatelessWidget {
  const _DetailInfoBlock({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      padding: const EdgeInsets.all(AppTheme.spacing14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: AppTheme.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.tag),
          const SizedBox(height: AppTheme.spacing6),
          Text(content, style: AppTheme.body),
        ],
      ),
    );
  }
}

class _SearchSuggestionCard extends StatelessWidget {
  const _SearchSuggestionCard();

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
      child: Text(
        'Nhập Hán tự, pinyin hoặc nghĩa tiếng Việt để tìm từ trong dữ liệu HSK.',
        style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard();

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
      child: Column(
        children: [
          const Icon(Icons.search_off, color: AppTheme.primary, size: 42),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'Không tìm thấy trong dữ liệu HSK hiện có',
            textAlign: TextAlign.center,
            style: AppTheme.bodyBold,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Hãy thử tìm bằng Hán tự, pinyin hoặc nghĩa tiếng Việt.',
            textAlign: TextAlign.center,
            style: AppTheme.subtitleMedium,
          ),
        ],
      ),
    );
  }
}
