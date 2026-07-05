import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/word_card.dart';
import 'favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);
    final actions = ref.read(favoritesActionsProvider);
    final favoritesNotifier = ref.read(favoritesProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: AppTheme.screenHorizontalPadding,
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacing16),
            _FavoritesHeader(onBack: () => _handleBack(context)),
            Expanded(
              child: favoritesAsync.when(
                data: (words) {
                  if (words.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chua co tu vung da luu',
                        style: AppTheme.headingMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(
                      top: AppTheme.spacing16,
                      bottom: AppTheme.spacing24,
                    ),
                    itemCount: words.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.cardGap),
                    itemBuilder: (context, index) {
                      final word = words[index];

                      return Dismissible(
                        key: ValueKey('favorite_${word.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(
                            right: AppTheme.spacing20,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: AppTheme.cardRadius,
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (_) async {
                          try {
                            await favoritesNotifier.removeWord(word);
                          } catch (_) {
                            if (!context.mounted) return;

                            await _showErrorDialog(
                              context,
                              message: 'Khong the bo luu tu, vui long thu lai.',
                            );
                            return;
                          }

                          if (!context.mounted) return;

                          final shouldRestore = await _showUndoDialog(context);

                          if (shouldRestore != true || !context.mounted) {
                            return;
                          }

                          try {
                            await favoritesNotifier.restoreWord(word);
                          } catch (_) {
                            if (!context.mounted) return;

                            await _showErrorDialog(
                              context,
                              message: 'Khong the hoan tac, vui long thu lai.',
                            );
                          }
                        },
                        child: WordCard(
                          hanzi: word.hanzi,
                          pinyin: word.pinyin,
                          meaning: word.meaningVi,
                          tags: [word.topic, 'HSK ${word.level}'],
                          isBookmarked: true,
                          showBookmark: false,
                          onSpeak: () {
                            actions.speakWord(word);
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
                error: (_, _) => const Center(
                  child: Text(
                    'Khong the tai tu da sao luu',
                    style: AppTheme.headingMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    context.go(AppRoutes.account);
  }

  Future<bool?> _showUndoDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing24,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: AppTheme.cardLargeRadius,
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đã bỏ lưu từ', style: AppTheme.headingMedium),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Bạn có muốn hoàn tác không?',
                  style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: AppTheme.spacing24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonSmallRadius,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing14,
                          ),
                        ),
                        child: const Text('Đóng'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppTheme.buttonSmallRadius,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacing14,
                          ),
                        ),
                        child: const Text('Hoàn tác'),
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
  }

  Future<void> _showErrorDialog(
    BuildContext context, {
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.cardLargeRadius),
          title: const Text('Co loi xay ra'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Dong'),
            ),
          ],
        );
      },
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Material(
            color: AppTheme.surface,
            borderRadius: AppTheme.appBarButtonRadius,
            child: InkWell(
              onTap: onBack,
              borderRadius: AppTheme.appBarButtonRadius,
              child: const SizedBox(
                width: AppTheme.appBarButtonSize,
                height: AppTheme.appBarButtonSize,
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Tu vung da sao luu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.appBarTitle,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.appBarButtonSize),
        ],
      ),
    );
  }
}
