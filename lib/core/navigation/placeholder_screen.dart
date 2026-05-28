import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text(title, style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
    );
  }
}
