import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bar_custom.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

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
              title: 'Quiz',
              actionIcon: Icons.bookmark_border,
            ),
            const Expanded(
              child: Center(
                child: Text('Quiz Screen', style: AppTheme.headingMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
