import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class SkillScoreBadge extends StatelessWidget {
  const SkillScoreBadge({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.leather.subtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Meu skill', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$score',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.leather,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
