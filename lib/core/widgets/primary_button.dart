import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.fullWidth = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool enabled;
  final bool fullWidth;

  bool get _canPress => enabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      onPressed: _canPress ? onPressed : null,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: Colors.transparent,
        backgroundColor: AppTheme.primary,
        disabledBackgroundColor: AppTheme.primaryLight.withOpacity(0.55),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withOpacity(0.8),
        padding: AppTheme.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.buttonRadius),
        minimumSize: Size(
          fullWidth ? double.infinity : 0,
          AppTheme.primaryButtonHeight,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                key: const ValueKey('content'),
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.button,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppTheme.spacing8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
