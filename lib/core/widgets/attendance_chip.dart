import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AttendanceChip extends StatelessWidget {
  const AttendanceChip({required this.label, required this.status, super.key});

  final String label;
  final AttendanceChipStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AttendanceChipStatus.confirmed => AppColors.success,
      AttendanceChipStatus.declined => Theme.of(context).colorScheme.secondary,
      AttendanceChipStatus.pending => AppColors.warning,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.subtle,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}

enum AttendanceChipStatus { confirmed, declined, pending }
