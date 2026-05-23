import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';

class SpeakingScreen extends StatelessWidget {
  const SpeakingScreen({super.key});

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
              title: 'Speaking',
              actionIcon: Icons.bookmark_border,
            ),
            const Expanded(
              child: Center(
                child: Text('Speaking Screen', style: AppTheme.headingMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
