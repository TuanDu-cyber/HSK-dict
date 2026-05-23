import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBarCustom extends StatelessWidget {
  const AppBarCustom({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actionIcon,
    this.onBack,
    this.onAction,
    this.height = 56,
  });

  final String title;
  final bool showBackButton;
  final IconData? actionIcon;
  final VoidCallback? onBack;
  final VoidCallback? onAction;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: showBackButton
                ? _AppBarIconButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: onBack ?? () => Navigator.maybePop(context),
                  )
                : const SizedBox(width: AppTheme.appBarButtonSize),
          ),
          Center(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.appBarTitle,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: actionIcon == null
                ? const SizedBox(width: AppTheme.appBarButtonSize)
                : _AppBarIconButton(icon: actionIcon!, onTap: onAction),
          ),
        ],
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: AppTheme.appBarButtonRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.appBarButtonRadius,
        child: SizedBox(
          width: AppTheme.appBarButtonSize,
          height: AppTheme.appBarButtonSize,
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
      ),
    );
  }
}
