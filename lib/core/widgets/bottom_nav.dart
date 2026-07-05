import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomNavItem {
  const BottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = const [
      BottomNavItem(icon: Icons.home_outlined, label: 'Trang chủ'),
      BottomNavItem(icon: Icons.search_outlined, label: 'Tìm kiếm'),
      BottomNavItem(icon: Icons.menu_book_outlined, label: 'Nối từ'),
      BottomNavItem(icon: Icons.person_outline, label: 'Cài đặt'),
    ],
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.screenPadding,
          vertical: AppTheme.spacing8,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing8,
          vertical: AppTheme.spacing10,
        ),
        decoration: BoxDecoration(
          color: AppTheme.navBg,
          borderRadius: AppTheme.bottomNavRadius,
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;

            return Expanded(
              child: _BottomNavButton(
                item: item,
                isActive: isActive,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.primary : AppTheme.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.buttonSmallRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primary : Colors.transparent,
                borderRadius: AppTheme.buttonSmallRadius,
              ),
              child: Icon(
                item.icon,
                size: AppTheme.bottomNavIconSize,
                color: isActive ? Colors.white : color,
              ),
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.navLabel.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
