import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.padding = AppSpacing.md});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}
