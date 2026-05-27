import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'attendance_chip.dart';

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    required this.name,
    required this.label,
    super.key,
    this.goalkeeper = false,
    this.guest = false,
  });

  final String name;
  final String label;
  final bool goalkeeper;
  final bool guest;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.leather.subtle,
          foregroundColor: AppColors.leather,
          child: Text(initial),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (goalkeeper) ...[
          const SizedBox(width: AppSpacing.sm),
          const _TinyBadge(label: 'GOL'),
        ],
        const SizedBox(width: AppSpacing.sm),
        AttendanceChip(
          label: guest ? 'Avulso' : label,
          status: AttendanceChipStatus.pending,
        ),
      ],
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.leather),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.leather,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
