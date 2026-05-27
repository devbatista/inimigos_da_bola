import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum StatusBannerStatus { offline, syncing, synced }

class StatusBanner extends StatelessWidget {
  const StatusBanner({required this.status, super.key, this.onTap});

  final StatusBannerStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, label) = switch (status) {
      StatusBannerStatus.offline => (
        AppColors.stone,
        Icons.cloud_off_outlined,
        'Offline',
      ),
      StatusBannerStatus.syncing => (
        AppColors.warning,
        Icons.sync,
        'Sincronizando...',
      ),
      StatusBannerStatus.synced => (
        AppColors.success,
        Icons.check_circle_outline,
        'Atualizado agora',
      ),
    };

    return Material(
      color: color.subtle,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
