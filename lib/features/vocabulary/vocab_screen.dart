import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';
import '../../core/widgets/bottom_nav.dart';

/// Deprecated placeholder. The `/vocabulary` route redirects to Search.
class VocabScreen extends StatelessWidget {
  const VocabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: AppTheme.screenHorizontalPadding,
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacing16),
            const AppBarCustom(title: 'Từ vựng'),
            const Expanded(
              child: Center(
                child: Text('Vocabulary Screen', style: AppTheme.headingMedium),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
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
    );
  }
}
