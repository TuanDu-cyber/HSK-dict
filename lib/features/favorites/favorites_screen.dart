import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: AppTheme.screenHorizontalPadding,
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacing16),
            const AppBarCustom(
              title: 'Từ vựng đã sao lưu',
              actionIcon: Icons.bookmark,
            ),
            const Expanded(
              child: Center(
                child: Text('Favorites Screen', style: AppTheme.headingMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
