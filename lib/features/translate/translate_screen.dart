import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bottom_nav.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: const Center(
        child: Text('Translate Screen', style: AppTheme.headingMedium),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 2,
        items: const [
          BottomNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
          BottomNavItem(icon: Icons.search_outlined, label: 'Tìm kiếm'),
          BottomNavItem(icon: Icons.translate_outlined, label: 'Dịch'),
          BottomNavItem(icon: Icons.person_outline, label: 'Cài đặt'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.go(AppRoutes.search);
              break;
            case 2:
              context.go(AppRoutes.translate);
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
