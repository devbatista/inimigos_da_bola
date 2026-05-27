import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SkillRatingSlider extends StatelessWidget {
  const SkillRatingSlider({
    required this.value,
    required this.onChanged,
    super.key,
    this.label = 'Nota',
  });

  final int value;
  final ValueChanged<int>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              '$clamped',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.leather,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.leather,
            inactiveTrackColor: AppColors.leather.subtle,
            thumbColor: AppColors.leather,
            overlayColor: AppColors.leather.pressed,
            valueIndicatorColor: AppColors.leather,
            valueIndicatorTextStyle: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.chalk,
            ),
          ),
          child: Slider(
            value: clamped.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            label: '$clamped',
            onChanged: onChanged == null
                ? null
                : (next) => onChanged!(next.round()),
          ),
        ),
      ],
    );
  }
}
