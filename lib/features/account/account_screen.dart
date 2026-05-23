import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';
import '../../core/widgets/bottom_nav.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: AppTheme.screenHorizontalPadding,
        child: Column(
          children: [
            const SizedBox(height: AppTheme.spacing16),
            const AppBarCustom(title: 'Tài khoản'),
            const Expanded(
              child: Center(
                child: Text('Account Screen', style: AppTheme.headingMedium),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: 3,
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
