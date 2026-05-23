import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    required this.controller,
    this.hintText = 'Tìm hanzi, pinyin hoặc nghĩa...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.prefixIcon = Icons.search,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final IconData prefixIcon;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          autofocus: autofocus,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: AppTheme.bodyMedium,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTheme.subtitleMedium,
            filled: true,
            fillColor: AppTheme.surface,
            prefixIcon: Icon(
              prefixIcon,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            suffixIcon: hasText
                ? IconButton(
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                      onChanged?.call('');
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                  )
                : null,
            contentPadding: AppTheme.inputPadding,
            border: OutlineInputBorder(
              borderRadius: AppTheme.inputRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.inputRadius,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.inputRadius,
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.4),
            ),
          ),
        );
      },
    );
  }
}
